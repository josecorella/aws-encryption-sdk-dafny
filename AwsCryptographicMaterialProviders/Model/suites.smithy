namespace aws.cryptography.materialProviders

///////////////////////////////////
// Algorithm Suites

// For now, the actual properties of algorithm suites are only used by internal
// components and are not actually customer facing. If and when we make them
// customer facing, we will need to either model the AlgorithmSuiteProperties
// as a separate structure (with an associated resource/operation for translating
// from name to properties) or use more advanced custom traits which allow us to
// model all properties of the algorithm suite in one structure. 
@enum([
  {
    name: "ALG_AES_128_GCM_IV12_TAG16_NO_KDF",
    value: "0x0014",
  },
  {
    name: "ALG_AES_192_GCM_IV12_TAG16_NO_KDF",
    value: "0x0046",
  },
  {
    name: "ALG_AES_256_GCM_IV12_TAG16_NO_KDF",
    value: "0x0078",
  },
  {
    name: "ALG_AES_128_GCM_IV12_TAG16_HKDF_SHA256",
    value: "0x0114",
  },
  {
    name: "ALG_AES_192_GCM_IV12_TAG16_HKDF_SHA256",
    value: "0x0146",
  },
  {
    name: "ALG_AES_256_GCM_IV12_TAG16_HKDF_SHA256",
    value: "0x0178",
  },
  {
    name: "ALG_AES_128_GCM_IV12_TAG16_HKDF_SHA256_ECDSA_P256",
    value: "0x0214",
  },
  {
    name: "ALG_AES_192_GCM_IV12_TAG16_HKDF_SHA384_ECDSA_P384",
    value: "0x0346",
  },
  {
    name: "ALG_AES_256_GCM_IV12_TAG16_HKDF_SHA384_ECDSA_P384",
    value: "0x0378",
  },
  {
    name: "ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY",
    value: "0x0478",
  },
  {
    name: "ALG_AES_256_GCM_HKDF_SHA512_COMMIT_KEY_ECDSA_P384",
    value: "0x0578",
  },
])
string ESDKAlgorithmSuiteId

union AlgorithmSuiteId {
  ESDK: ESDKAlgorithmSuiteId
}

structure AlgorithmSuiteInfo {
  @required
  id: AlgorithmSuiteId,
  @required
  binaryId: Blob,
  @required
  messageVersion: Integer,
  @required
  encrypt: Encrypt,
  @required
  kdf: DerivationAlgorithm,
  @required
  commitment: DerivationAlgorithm,
  @required
  signature: SignatureAlgorithm,
}
 
union Encrypt {
  AES_GCM: aws.cryptography.primitives#AES_GCM,
}

union DerivationAlgorithm {
  HKDF: HKDF,
  // We are using both `IDENTITY` and `None` here
  // to modle the fact that deriving
  // the data encryption key and the commitment key
  // MUST be the same.
  // The specification treats NO_KDF as an identity operation.
  // So this naming convention mirrors the specification.
  IDENTITY: IDENTITY,
  None: None,
}

union SignatureAlgorithm {
  ECDSA: ECDSA,
  None: None
}

structure HKDF {
  @required
  hmac: aws.cryptography.primitives#DigestAlgorithm,
  @required
  saltLength: aws.cryptography.primitives#PositiveInteger,
  @required
  inputKeyLength: aws.cryptography.primitives#SymmetricKeyLength,
  @required
  outputKeyLength: aws.cryptography.primitives#SymmetricKeyLength,
}
structure IDENTITY {}
structure None {}

structure ECDSA {
  @required
  curve: aws.cryptography.primitives#ECDSASignatureAlgorithm,
}

@readonly
operation GetAlgorithmSuiteInfo {
  input: GetAlgorithmSuiteInfoInput,
  output: AlgorithmSuiteInfo,
}

@aws.polymorph#positional
structure GetAlgorithmSuiteInfoInput {
  @required
  binaryId: Blob
}

@readonly
operation ValidAlgorithmSuiteInfo {
  input: AlgorithmSuiteInfo,
  errors: [InvalidAlgorithmSuiteInfo]
}

@error("client")
structure InvalidAlgorithmSuiteInfo {
  @required
  message: String,
}
