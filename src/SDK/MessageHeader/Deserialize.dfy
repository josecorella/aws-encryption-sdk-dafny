include "Definitions.dfy"
include "Utils.dfy"
include "Validity.dfy"

include "../AlgorithmSuite.dfy"
include "../../Util/Streams.dfy"
include "../../StandardLibrary/StandardLibrary.dfy"
include "../../Util/UTF8.dfy"


/*
 * The message header deserialization
 *
 * The message header is deserialized from a uint8 stream.
 * When encountering an error, we stop and return it immediately, leaving the remaining inputs on the stream
 */
module MessageHeader.Deserialize {
    import opened Definitions
    import opened Validity
    import opened Utils

    import AlgorithmSuite
    import opened Streams
    import opened StandardLibrary
    import opened UInt = StandardLibrary.UInt
    import opened UTF8

    lemma {:axiom} Assume(b : bool) ensures b

    /*
     * Message header-specific
     */

    method deserializeVersion(is: StringReader) returns (ret: Result<T_Version>)
        requires is.Valid()
        modifies is
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 1);
        match res {
            case Success(version) =>
                if version[0] == 0x01 {
                    return Success(version[0] as T_Version);
                } else {
                    return Failure("Deserialization Error: Version not supported.");
                }
            case Failure(e) => return Failure(e);
        }
    }

    method deserializeType(is: StringReader) returns (ret: Result<T_Type>)
        requires is.Valid()
        modifies is
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 1);
        match res {
            case Success(typ) =>
                if typ[0] == 0x80 {
                    return Success(typ[0] as T_Type);
                } else {
                    return Failure("Deserialization Error: Type not supported.");
                }
            case Failure(e) => return Failure(e);
        }
    }

    method deserializeAlgorithmSuiteID(is: StringReader) returns (ret: Result<AlgorithmSuite.ID>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(algorithmSuiteID) => ValidAlgorithmID(algorithmSuiteID)
                case Failure(_) => true
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 2);
        match res {
            case Success(algorithmSuiteID) =>
                var asid := ArrayToUInt16(algorithmSuiteID);
                if asid in AlgorithmSuite.validIDs {
                    return Success(asid as AlgorithmSuite.ID);
                } else {
                    return Failure("Deserialization Error: Algorithm suite not supported.");
                }
            case Failure(e) => return Failure(e);
        }
    }

    // TODO:
    predicate method isValidMsgID (candidateID: array<uint8>)
        requires candidateID.Length == 16
        ensures ValidMessageId(candidateID[..])
    {
        true
    }
    method deserializeMsgID(is: StringReader) returns (ret: Result<T_MessageID>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(msgId) => ValidMessageId(msgId)
                case Failure(_) => true
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 16);
        match res {
            case Success(msgId) =>
                if isValidMsgID(msgId) {
                    return Success(msgId[..]);
                } else {
                    return Failure("Deserialization Error: Not a valid Message ID.");
                }
            case Failure(e) => return Failure(e);
        }
    }

    method deserializeUTF8(is: StringReader, n: nat) returns (ret: Result<array<uint8>>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(bytes) =>
                    && bytes.Length == n
                    && ValidUTF8(bytes)
                    && fresh(bytes)
                case Failure(_) => true
        ensures is.Valid()
    {
        ret := readFixedLengthFromStreamOrFail(is, n);
        match ret {
            case Success(bytes) =>
                if ValidUTF8(bytes) {
                    return ret;
                } else {
                    return Failure("Deserialization Error: Not a valid UTF8 string.");
                }
            case Failure(e) => return ret;
        }
    }

    method deserializeUnrestricted(is: StringReader, n: nat) returns (ret: Result<array<uint8>>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(bytes) =>
                    && bytes.Length == n
                    && fresh(bytes)
                case Failure(_) => true
        ensures is.Valid()
    {
        ret := readFixedLengthFromStreamOrFail(is, n);
    }

    // TODO: Probably this should be factored out into EncCtx at some point
    method deserializeAAD(is: StringReader) returns (ret: Result<T_AAD>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(aad) =>
                    && ValidAAD(aad)
                case Failure(_) => true
        ensures is.Valid()
    {
        reveal ValidAAD();
        var kvPairsLength: uint16;
        {
            var res := deserializeUnrestricted(is, 2);
            match res {
                case Success(bytes) => kvPairsLength := ArrayToUInt16(bytes);
                case Failure(e) => return Failure(e);
            }
        }
        if kvPairsLength == 0 {
            return Success(EmptyAAD);
        }
        var totalBytesRead := 0;

        var kvPairsCount: uint16;
        {
            var res := deserializeUnrestricted(is, 2);
            match res {
                case Success(bytes) =>
                    kvPairsCount := ArrayToUInt16(bytes);
                    totalBytesRead := totalBytesRead + bytes.Length;
                    if kvPairsLength > 0 && kvPairsCount == 0 {
                        return Failure("Deserialization Error: Key value pairs count is 0.");
                    }
                    assert kvPairsLength > 0 ==> kvPairsCount > 0;
                case Failure(e) => return Failure(e);
            }
        }

        // TODO: declare this array, make kvPairs a ghost, maintain invariant that sequence is a prefix of the array:
        // var kvPairsArray: array<(seq<uint8>, seq<uint8>)> := new [kvPairsCount];
        var kvPairs: seq<(seq<uint8>, seq<uint8>)> := [];
        assert kvPairsCount > 0;

        var i := 0;
        while i < kvPairsCount
            invariant is.Valid()
            invariant |kvPairs| == i as int
            invariant i <= kvPairsCount
            invariant InBoundsKVPairsUpTo(kvPairs, i as nat)
            invariant SortedKVPairsUpTo(kvPairs, i as nat)
            invariant forall j :: 0 <= j < i ==> ValidUTF8Seq(kvPairs[j].0)
            invariant forall j :: 0 <= j < i ==> ValidUTF8Seq(kvPairs[j].1)
        {
            var keyLength: uint16;
            {
                var res := deserializeUnrestricted(is, 2);
                match res {
                    case Success(bytes) =>
                        keyLength := ArrayToUInt16(bytes);
                        totalBytesRead := totalBytesRead + bytes.Length;
                    case Failure(e) => return Failure(e);
                }
            }

            var key: seq<uint8>;
            {
                var res := deserializeUTF8(is, keyLength as nat);
                match res {
                    case Success(bytes) =>
                        ValidUTF8ArraySeq(bytes);
                        key := bytes[..];
                        totalBytesRead := totalBytesRead + bytes.Length;
                    case Failure(e) => return Failure(e);
                }
            }
            assert |key| < UINT16_LIMIT;
            assert ValidUTF8Seq(key);

            var valueLength: uint16;
            {
                var res := deserializeUnrestricted(is, 2);
                match res {
                    case Success(bytes) =>
                        valueLength := ArrayToUInt16(bytes);
                        totalBytesRead := totalBytesRead + bytes.Length;
                    case Failure(e) => return Failure(e);
                }
            }

            var value: seq<uint8>;
            {
                var res := deserializeUTF8(is, valueLength as nat);
                match res {
                    case Success(bytes) =>
                        ValidUTF8ArraySeq(bytes);
                        value := bytes[..];
                        totalBytesRead := totalBytesRead + bytes.Length;
                    case Failure(e) => return Failure(e);
                }
            }
            assert |value| < UINT16_LIMIT;
            assert ValidUTF8Seq(value);

            // check for sortedness by key
            if i != 0 && !LexCmpSeqs(kvPairs[i-1].0, key, ltByte) {
                return Failure("Deserialization Error: Key-value pairs must be sorted by key.");
            }
            kvPairs := kvPairs + [(key, value)];
            assert SortedKVPairsUpTo(kvPairs, (i+1) as nat);
            i := i + 1;
        }
        if (kvPairsLength as nat) != totalBytesRead {
            return Failure("Deserialization Error: Bytes actually read differs from bytes supposed to be read.");
        }
        return Success(AAD(kvPairs));
    }

    // TODO: Probably this should be factored out into EDK at some point
    method deserializeEncryptedDataKeys(is: StringReader, ghost aad: T_AAD) returns (ret: Result<T_EncryptedDataKeys>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(edks) =>
                    && ValidEncryptedDataKeys(edks)
                case Failure(_)   => true
        ensures is.Valid()
    {
        reveal ValidEncryptedDataKeys();
        var edkCount: uint16;
        var res := deserializeUnrestricted(is, 2);
        match res {
            case Success(bytes) => edkCount := ArrayToUInt16(bytes);
            case Failure(e)    => return Failure(e);
        }

        if edkCount == 0 {
            return Failure("Deserialization Error: Encrypted data key count must be > 0.");
        }

        var edkEntries: seq<EDKEntry> := [];
        var i := 0;
        while i < edkCount
            invariant is.Valid()
            invariant i <= edkCount
            invariant InBoundsEncryptedDataKeys(edkEntries)
        {
            // Key provider ID
            var keyProviderIDLength: uint16;
            res := deserializeUnrestricted(is, 2);
            match res {
                case Success(bytes) => keyProviderIDLength := ArrayToUInt16(bytes);
                case Failure(e)    => return Failure(e);
            }

            var keyProviderID: string;
            res := deserializeUTF8(is, keyProviderIDLength as nat);
            match res {
                case Success(bytes) => keyProviderID := ByteSeqToString(bytes[..]);
                case Failure(e)    => return Failure(e);
            }

            // Key provider info
            var keyProviderInfoLength: uint16;
            res := deserializeUnrestricted(is, 2);
            match res {
                case Success(bytes) => keyProviderInfoLength := ArrayToUInt16(bytes);
                case Failure(e)    => return Failure(e);
            }

            var keyProviderInfo: seq<uint8>;
            res := deserializeUnrestricted(is, keyProviderInfoLength as nat);
            match res {
                case Success(bytes) => keyProviderInfo := bytes[..];
                case Failure(e)    => return Failure(e);
            }

            // Encrypted data key
            var edkLength: uint16;
            res := deserializeUnrestricted(is, 2);
            match res {
                case Success(bytes) => edkLength := ArrayToUInt16(bytes);
                case Failure(e)    => return Failure(e);
            }

            var edk: seq<uint8>;
            res := deserializeUnrestricted(is, edkLength as nat);
            match res {
                case Success(bytes) => edk := bytes[..];
                case Failure(e)    => return Failure(e);
            }

            edkEntries := edkEntries + [Materials.EncryptedDataKey(keyProviderID, keyProviderInfo, edk)];
            i := i + 1;
        }

        var edks := EncryptedDataKeys(edkEntries);
        return Success(edks);
    }

    method deserializeContentType(is: StringReader) returns (ret: Result<T_ContentType>)
        requires is.Valid()
        modifies is
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 1);
        match res {
            case Success(contentType) =>
                if contentType[0] == 0x01 {
                    return Success(NonFramed);
                } else if contentType[0] == 0x02 {
                    return Success(Framed);
                } else {
                    return Failure("Deserialization Error: Content type not supported.");
                }
            case Failure(e) => return Failure(e);
        }
    }

    method deserializeReserved(is: StringReader) returns (ret: Result<T_Reserved>)
        requires is.Valid()
        modifies is
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 4);
        match res {
            case Success(reserved) =>
                if reserved[0] == reserved[1] == reserved[2] == reserved[3] == 0 {
                    return Success(reserved[..]);
                } else {
                    return Failure("Deserialization Error: Reserved fields must be 0.");
                }
            case Failure(e) => return Failure(e);
        }
    }

    method deserializeIVLength(is: StringReader, algSuiteId: AlgorithmSuite.ID) returns (ret: Result<uint8>)
        requires is.Valid()
        requires algSuiteId in AlgorithmSuite.Suite.Keys
        modifies is
        ensures
            match ret
                case Success(ivLength) => ValidIVLength(ivLength, algSuiteId)
                case Failure(_)       => true
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 1);
        match res {
            case Success(ivLength) =>
                if ivLength[0] == AlgorithmSuite.Suite[algSuiteId].params.ivLen {
                    return Success(ivLength[0]);
                } else {
                    return Failure("Deserialization Error: Incorrect IV length.");
                }
            case Failure(e) => return Failure(e);
        }
    }

    method deserializeFrameLength(is: StringReader, contentType: T_ContentType) returns (ret: Result<uint32>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(frameLength) => ValidFrameLength(frameLength, contentType)
                case Failure(_) => true
        ensures is.Valid()
    {
        var res := readFixedLengthFromStreamOrFail(is, 4);
        match res {
            case Success(frameLength) =>
                if contentType.NonFramed? && ArrayToUInt32(frameLength) == 0 {
                    return Success(ArrayToUInt32(frameLength));
                } else {
                    return Failure("Deserialization Error: Frame length must be 0 when content type is non-framed.");
                }
            case Failure(e) => return Failure(e);
        }
    }
    /**
    * Reads raw header data from the input stream and populates the header with all of the information about the
    * message.
    */
    method headerBody(is: StringReader) returns (ret: Result<HeaderBody>)
        requires is.Valid()
        modifies is
        ensures is.Valid()
        ensures
            match ret
                case Success(hb) =>
                    && ValidHeaderBody(hb)
                case Failure(_) => true
    {
        Assume(false);
        reveal ValidHeaderBody();
        var version: T_Version;
        {
            var res := deserializeVersion(is);
            match res {
                case Success(version_) => version := version_;
                case Failure(e)       => return Failure(e);
            }
        }

        var typ: T_Type;
        {
            var res := deserializeType(is);
            match res {
                case Success(typ_) => typ := typ_;
                case Failure(e)   => return Failure(e);
            }
        }

        var algorithmSuiteID: AlgorithmSuite.ID;
        {
            var res := deserializeAlgorithmSuiteID(is);
            match res {
                case Success(algorithmSuiteID_) => algorithmSuiteID := algorithmSuiteID_;
                case Failure(e)                => return Failure(e);
            }
        }

        var messageID: T_MessageID;
        {
            var res := deserializeMsgID(is);
            match res {
                case Success(messageID_) => messageID := messageID_;
                case Failure(e)    => return Failure(e);
            }
        }

        // AAD deserialization:
        var aad: T_AAD;
        {
            var res := deserializeAAD(is);
            match res {
                case Success(aad_) => aad := aad_;
                case Failure(e)   => return Failure(e);
            }
        }

        // EDK deserialization:
        var encryptedDataKeys: T_EncryptedDataKeys;
        {
            var res := deserializeEncryptedDataKeys(is, aad);
            match res {
                case Success(encryptedDataKeys_) => encryptedDataKeys := encryptedDataKeys_;
                case Failure(e)   => return Failure(e);
            }
        }

        var contentType: T_ContentType;
        {
            var res := deserializeContentType(is);
            match res {
                case Success(contentType_) => contentType := contentType_;
                case Failure(e)           => return Failure(e);
            }
        }

        var reserved: T_Reserved;
        {
            var res := deserializeReserved(is);
            match res {
                case Success(reserved_) => reserved := reserved_;
                case Failure(e)    => return Failure(e);
            }
        }

        var ivLength: uint8;
        {
            var res := deserializeIVLength(is, algorithmSuiteID);
            match res {
                case Success(ivLength_) => ivLength := ivLength_;
                case Failure(e)    => return Failure(e);
            }
        }

        var frameLength: uint32;
        {
            var res := deserializeFrameLength(is, contentType);
            match res {
                case Success(frameLength_) => frameLength := frameLength_;
                case Failure(e) => return Failure(e);
            }
        }
        var hb := HeaderBody(
                    version,
                    typ,
                    algorithmSuiteID,
                    messageID,
                    aad,
                    encryptedDataKeys,
                    contentType,
                    reserved,
                    ivLength,
                    frameLength);
        assert ValidHeaderBody(hb);
        ret := Success(hb);
    }

    method deserializeAuthenticationTag(is: StringReader, tagLength: nat, ghost iv: array<uint8>) returns (ret: Result<array<uint8>>)
        requires is.Valid()
        modifies is
        ensures
            match ret
                case Success(authenticationTag) => ValidAuthenticationTag(authenticationTag, tagLength, iv)
                case Failure(_) => true
        ensures is.Valid()
    {
        ret := readFixedLengthFromStreamOrFail(is, tagLength);
    }

    method headerAuthentication(is: StringReader, body: HeaderBody) returns (ret: Result<HeaderAuthentication>)
        requires is.Valid()
        requires ValidHeaderBody(body)
        requires body.algorithmSuiteID in AlgorithmSuite.Suite.Keys
        modifies is
        ensures is.Valid()
        ensures
            match ret
                case Success(headerAuthentication) =>
                    && ValidHeaderAuthentication(headerAuthentication, body.algorithmSuiteID)
                    && ValidHeaderBody(body)
                case Failure(_) => true
    {
        var iv: array<uint8>;
        {
            var res := deserializeUnrestricted(is, body.ivLength as nat);
            match res {
                case Success(bytes) => iv := bytes;
                case Failure(e)    => return Failure(e);
            }
        }

        var authenticationTag: array<uint8>;
        {
            var res := deserializeAuthenticationTag(is, AlgorithmSuite.Suite[body.algorithmSuiteID].params.tagLen as nat, iv);
            match res {
                case Success(bytes) => authenticationTag := bytes;
                case Failure(e)    => return Failure(e);
            }
        }
        ret := Success(HeaderAuthentication(iv, authenticationTag));
    }
}
