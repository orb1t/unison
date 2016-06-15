module Unison.Runtime.ProcessPool where

import Data.Bytes.Serial
import System.Process (ProcessHandle)

newtype TimeBudget = Seconds Int
newtype SpaceBudget = Megabytes Int
type Budget = (TimeBudget, SpaceBudget)
newtype MaxProcesses = MaxProcesses Int
data Err = TimeExceeded | SpaceExceeded | Killed | InsufficientProcesses
type ID = Int

data Pool a b = Pool {
  -- | Evaluate the thunk in a separate process, with the given budget.
  -- The outer IO completes immediately yielding a tuple containing the ID
  -- of the process being used for evaluation and another IO which, when
  -- it completes, yields the result of the evaluation.
  -- If there is no available process for that `Budget`, create a new one, 
  -- unless that would exceed the `MaxProcesses` bound, in which case
  -- fail fast with `Left InsufficientProcesses`.
  evaluate :: Budget -> a -> IO (ID, IO (Either Err b)),

  -- | Forcibly kill the process associated with an ID. Any prior `evaluate` for
  -- that `ID` should complete with `Left Killed`.
  kill :: ID -> IO (),

  -- | Shutdown the entire pool. After this completes, no other processes should be running
  shutdown :: IO ()
}

pool :: (Serial a, Serial b) => IO ProcessHandle -> MaxProcesses -> IO (Pool a b)
pool createWorker = undefined
