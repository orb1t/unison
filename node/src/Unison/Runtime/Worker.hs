module Unison.Runtime.Worker where

import Data.Bytes.Serial

worker :: (Serial a, Serial b) => (a -> IO b) -> IO ()
worker eval = undefined

main :: IO ()
main = undefined
