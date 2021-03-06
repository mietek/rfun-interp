---------------------------------------------------------------------------
--
-- Module      :  TypeCheck
-- Copyright   :  Michael Kirkedal Thomsen, 2017
-- License     :  AllRightsReserved
--
-- Maintainer  :  Michael Kirkedal Thomsen <kirkedal@acm.org>
-- Stability   :  none?
-- Portability :  ?
--
-- |Main execution of RFun17 interpreter
--
-----------------------------------------------------------------------------

module Main (main) where

import Parser
import Ast
import PrettyPrinter
import TypeCheck
import Interp

import System.Environment
import System.Exit
import System.Timeout


main :: IO ()
main =
  do
    args <- getArgs
    case args of
      [program, values, filename] ->
        do p <- parseProgram filename
           vs <- parseValues [values]
           case typecheck p of
             (Just e) -> putStrLn e
             Nothing  ->
               do res <- timeout (5 * 1000000) $ (return $ interp p program vs)
                  case res of
                    Just (Left err)  -> putStrLn "Run-time error:" >> (putStrLn $ err)
                    Just (Right val) -> putStrLn $ ppValue val
                    Nothing -> exitWith $ ExitFailure 124
      _ -> putStrLn "Wrong number of arguments.\nUsage:\n  \"rfun\" programfile startfunc startvalue+\nor to stop before interpretation:\n  \"rfun\" programfile "

typecheckProgram :: Program -> IO Program
typecheckProgram p =
  case typecheck p of
        Nothing  -> return p
        (Just e) -> putStrLn e >> (exitWith $ ExitFailure 1)

prettyPrintProgram :: Program -> IO ()
prettyPrintProgram = putStrLn.ppProgram

parseProgram :: String -> IO Program
parseProgram "-" =
  do str <- getContents
     parseFromString str >>= fromParserError
parseProgram filename = parseFromFile filename >>= fromParserError

parseValues :: [String] -> IO [Value]
parseValues strV =
  do l <- fromParserError $ mapM parseFromValue strV
     return $ concat l

fromParserError :: Either ParserError a -> IO a
fromParserError (Left err) = (putStr (prettyParseError err)) >> (exitWith $ ExitFailure 1)
fromParserError (Right a)  = return a

