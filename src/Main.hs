{-# LANGUAGE TupleSections #-}

module Main where

import Control.Monad 
import Control.Exception (throw, ErrorCall(..))
import Data.Maybe (catMaybes)
import Data.List ((\\))
import System.Directory (doesDirectoryExist, createDirectoryIfMissing, getDirectoryContents,removeDirectoryRecursive)
import System.Process (callCommand)
import System.Environment (getEnv, getArgs)
import qualified Data.ByteString.Char8 as BS
import qualified Github.Repos as G
import qualified Github.Data.Definitions as GD
import qualified Github.Auth as GA

gitDir = "./repos/"

handle :: (Show e) => String -> IO (Either e r) -> IO r
handle msg io = 
  flip fmap io $ either (\err -> error $ msg ++ ": " ++ show err) id 

findWithParents :: String -> GA.GithubAuth -> IO [(GD.RepoRef, GD.RepoRef)]
findWithParents owner auth = do
  repos <- handle "Couldn't fetch repo list" $ G.userRepos' (Just auth) owner G.Owner
  let forks = filter (\r -> G.repoFork r == Just True) repos
  details <- forM forks $ \fork -> 
    let name = G.repoName fork
     in handle ("Couldn't fetch " ++ name) $ G.userRepo' (Just auth) owner name
  let pack r = GD.RepoRef (GD.repoOwner r) (GD.repoName r)
  return $ catMaybes $ (\r -> (pack r,) `fmap` G.repoParent r) `fmap` details


renderRepoRef :: GD.RepoRef -> String
renderRepoRef (GD.RepoRef owner name) = 
  "https://github.com/" ++ GD.githubOwnerLogin owner ++ "/" ++ name

ensureClone :: String -> GD.RepoRef -> GD.RepoRef -> IO ()
ensureClone owner repoRef@(GD.RepoRef _ repoName) parentRef = do
  let repo = renderRepoRef repoRef
      parent = renderRepoRef parentRef
      dir = gitDir ++ repoName
  exists <- doesDirectoryExist dir
  when (not exists) $ do
    callCommand $ "git clone " ++ repo ++ " " ++ dir
    callCommand $ "cd " ++ dir ++ ";git remote add upstream " ++ parent
  callCommand $ "cd " ++ dir ++ "; git fetch origin; git fetch upstream"


forkUpdater auth owner = do 
  putStrLn "fetching metadata from github"
  pairs <- findWithParents owner auth
 
  putStrLn "fetching repos"
  createDirectoryIfMissing True gitDir
  forM_ pairs $ \(r,p) ->
    ensureClone owner r p
  
  let names = flip map pairs $ \(GD.RepoRef _ name, _) -> name

  putStrLn "removing old forks"
  clones <- getDirectoryContents gitDir
  let toRemove = (clones \\ [".", ".."]) \\ names
  print toRemove
  forM_ toRemove $ \r -> removeDirectoryRecursive $ gitDir ++ r
  putStrLn ""

  putStrLn "----------"
  putStrLn "new commits"
  putStrLn "----------\n"

  forM_ names $ \r -> do
    putStrLn r
    putStrLn "----------"
    callCommand $ "cd " ++ gitDir ++ r ++ "; git log origin/master..upstream/master --oneline"
    putStrLn "\n"


printHelp = do
  putStrLn "Usage: fork-updater github_user"
  putStrLn ""
  putStrLn "It will load your github username from GITHUB_USER"
  putStrLn "and password from GITHUB_PASSWORD"
  putStrLn "and use ./repos/ folder"


main = do
  user <- getEnv "GITHUB_USER"
  password <- getEnv "GITHUB_PASSWORD"
  args <- getArgs
  owner <- case args of [x] -> return x
                        _   -> printHelp >> (throw $ ErrorCall "Couldn't load owner")
  let auth = GA.GithubBasicAuth (BS.pack user) (BS.pack password)
  forkUpdater auth owner
  

