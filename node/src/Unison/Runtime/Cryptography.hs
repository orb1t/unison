{-# LANGUAGE OverloadedStrings #-}
{-# Language ScopedTypeVariables #-}

module Unison.Runtime.Cryptography where

import Unison.Cryptography
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import Data.ByteArray as BA
import Crypto.Error (throwCryptoError)
import qualified Crypto.Random as R
import qualified Crypto.Noise.Cipher as C
import qualified Crypto.Noise.Cipher.ChaChaPoly1305 as CCP
import qualified Crypto.Cipher.ChaChaPoly1305 as CCP2

-- Creates a Unison.Cryptography object specialized to use the noise protocol
-- (http://noiseprotocol.org/noise.html).
mkCrypto :: forall cleartext symmetricKey . (ByteArrayAccess cleartext, ByteArray cleartext, ByteArrayAccess symmetricKey, ByteArray symmetricKey) => ByteString -> Cryptography ByteString symmetricKey () () () () cleartext
mkCrypto key = Cryptography key gen hash sign verify randomBytes encryptAsymmetric decryptAsymmetric encrypt decrypt pipeInitiator pipeResponder where
  -- generates an elliptic curve keypair, for use in ECDSA
  gen = undefined
  hash = undefined
  sign _ = undefined
  verify _ _ _ = undefined
  randomBytes = randomBytes'
  encryptAsymmetric _ cleartext = undefined
  decryptAsymmetric ciphertext = undefined

  encrypt :: symmetricKey -> [cleartext] -> IO Ciphertext
  encrypt = encrypt'
      
  decrypt :: symmetricKey -> ByteString -> Either String cleartext
  decrypt = decrypt'

  pipeInitiator _ = undefined
  pipeResponder = undefined

randomBytes' :: Int -> IO ByteString
randomBytes' n = do drg <- R.getSystemDRG
                    let bts = fst $ R.randomBytesGenerate n drg
                    return bts

encrypt' :: ( ByteArrayAccess cleartext
            --, ByteArray cleartext
            , ByteArrayAccess symmetricKey)
         => symmetricKey
         -> [cleartext]
         -> IO Ciphertext
encrypt' k cts = do
  let clrtext = BA.concat cts :: cleartext
      assocData = ""
      nonce = throwCryptoError $ CCP2.nonce12 (randomBytes' 12) -- nonce = 12 bytes
      initState = throwCryptoError $ CCP2.initialize k nonce
      afterAAD = CCP2.finalizeAAD (CCP2.appendAAD assocData initState)
      (ciphertext, finalState) = CCP2.encrypt clrtext afterAAD
      authTag = CCP2.finalize finalState -- authTag = 16 bytes
      out = BA.concat [(BA.convert nonce), (BA.convert ciphertext), (BA.convert authTag)]
--  return $ BA.convert out
  return out

decrypt' :: ( ByteArrayAccess symmetricKey
            , ByteArray cleartext)
         => symmetricKey
         -> ByteString
         -> Either String cleartext
decrypt' k ct = let key = C.cipherBytesToSym (BA.convert k) :: C.SymmetricKey CCP.ChaChaPoly1305
                    ciphertext = C.cipherBytesToText (BA.convert ct) :: C.Ciphertext CCP.ChaChaPoly1305
                    nonce = C.cipherZeroNonce :: C.Nonce CCP.ChaChaPoly1305
                    ad = "" :: C.AssocData
                in
                  case C.cipherDecrypt key nonce ad ciphertext of
                    Nothing -> Left "Could not decrypt ciphertext; authentication failure."
                    Just clrtext -> Right $ BA.convert clrtext
