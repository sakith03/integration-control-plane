// Copyright (c) 2026, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/crypto;
import ballerina/file;
import ballerina/os;
import ballerina/lang.array;

// Cipher tool keystore configuration.
// This keystore is separate from the Ballerina TLS keystore (ballerinaKeystore.p12)
// and is used exclusively for encrypting/decrypting secrets via the WSO2 cipher tool.
configurable string cipherKeystorePath = check file:joinPath("..", "conf", "security", "keystore.p12");

// Password for the cipher keystore.
// Resolved at runtime: ICP_CIPHER_KEYSTORE_PASSWORD env var takes precedence over this configurable.
// One of the two must be set when encrypted secrets are present.
configurable string cipherKeystorePassword = "changeit";

// Decrypts a value encrypted by the WSO2 cipher tool using asymmetric RSA/ECB/OAEPwithSHA1andMGF1Padding.
// Returns an error if decryption fails (including if the value is not a valid encrypted secret).
public function decrypt(string encryptedValue) returns string|error {
    string password = os:getEnv("ICP_CIPHER_KEYSTORE_PASSWORD");
    if password == "" {
        password = cipherKeystorePassword;
    }
    if password == "" {
        return error("Cipher keystore password is not configured. " +
                     "Set the ICP_CIPHER_KEYSTORE_PASSWORD environment variable " +
                     "or the cipherKeystorePassword configurable.");
    }

    crypto:KeyStore keyStore = {
        path: cipherKeystorePath,
        password: password
    };
    crypto:PrivateKey privateKey = check crypto:decodeRsaPrivateKeyFromKeyStore(keyStore, "localhost", password);
    byte[] encryptedBytes = check array:fromBase64(encryptedValue);
    byte[] decryptedBytes = check crypto:decryptRsaEcb(encryptedBytes, privateKey, crypto:OAEPWithSHA1AndMGF1);
    string decryptedKey = check string:fromBytes(decryptedBytes);
    return decryptedKey;
}
