include "Definitions.dfy"
include "Deserialize.dfy"
include "Serialize.dfy"
include "Validity.dfy"

include "../AlgorithmSuite.dfy"
include "../../Util/Streams.dfy"
include "../../StandardLibrary/StandardLibrary.dfy"

module MessageHeader {
    import AlgorithmSuite
    import opened StandardLibrary
    import opened Streams

    /*
     * Definition of the message header, i.e., the header body and the header authentication
     */
    class Header {
        var body: Option<Definitions.HeaderBody>
        var auth: Option<Definitions.HeaderAuthentication>

        constructor () {
            body := None;
            auth := None;
        }

        method deserializeHeader(is: StringReader)
            requires is.Valid()
            modifies is, `body, `auth
            requires body.None? || auth.None?
            ensures body.Some? && auth.Some? ==> Validity.ValidHeaderBody(body.get)
            ensures body.Some? && auth.Some? ==> Validity.ValidHeaderAuthentication(auth.get, body.get.algorithmSuiteID)
            // TODO: is this the right decision?
            ensures body.Some? <==> auth.Some?
            ensures body.None? <==> auth.None? // redundant
            ensures is.Valid()
        {
            {
                var res := Deserialize.headerBody(is);
                match res {
                    case Success(body_) =>
                        // How does Dafny know the following assertion holds with Validity.ValidHeaderBody being opaque?
                        assert body_.algorithmSuiteID in AlgorithmSuite.Suite.Keys; // nfv
                        var res := Deserialize.headerAuthentication(is, body_);
                        match res {
                            case Success(auth_) =>
                                body := Some(body_);
                                auth := Some(auth_);
                                assert Validity.ValidHeaderBody(body.get);
                            case Failure(e)    => {
                                print "Could not deserialize message header: " + e + "\n";
                                body := None;
                                auth := None;
                                return;
                            }
                        }
                    case Failure(e)    => {
                        print "Could not deserialize message header: " + e + "\n";
                        body := None;
                        auth := None;
                        return;
                    }
                }
            }
        }

        method serializeHeader(os: StringWriter) returns (ret: Result<nat>)
            requires os.Valid()
            requires body.Some?
            requires Validity.ValidHeaderBody(body.get)
            modifies os.Repr
            ensures os.Valid()
        {
            ret := Serialize.headerBody(os, body.get);
        }
    }
}
