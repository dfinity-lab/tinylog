-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE OverloadedStrings #-}

module System.Logger.Settings
    ( Settings
    , Level      (..)
    , Output     (..)
    , DateFormat (..)

    , defSettings
    , output
    , setOutput
    , immFlush
    , setImmFlush
    , format
    , setFormat
    , bufSize
    , setBufSize
    , delimiter
    , setDelimiter
    , color
    , setColor
    , netstrings
    , setNetStrings
    , logLevel
    , logLevelMap
    , logLevelOf
    , setLogLevel
    , setLogLevelMap
    , setLogLevelOf
    , name
    , setName
    , nameMsg
    , setNameMsg
    , iso8601UTC
    ) where

import Data.String
import Data.ByteString (ByteString)
import Data.ByteString.Char8 (pack)
import Data.Map.Strict as Map
import Data.Text (Text)
import Data.UnixTime
import System.Log.FastLogger (defaultBufSize)
import System.Logger.Message

data Settings = Settings
    { _logLevel   :: !Level              -- ^ messages below this log level will be suppressed
    , _levelMap   :: !(Map Text Level)   -- ^ log level per named logger
    , _output     :: !Output             -- ^ log sink
    , _immFlush   :: !Bool               -- ^ flush every message immediately
    , _format     :: !(Maybe DateFormat) -- ^ the timestamp format (use 'Nothing' to disable timestamps)
    , _delimiter  :: !ByteString         -- ^ text to intersperse between fields of a log line
    , _color      :: !Bool               -- ^ color by log level
    , _netstrings :: !Bool               -- ^ use <http://cr.yp.to/proto/netstrings.txt netstrings> encoding (fixes delimiter to \",\")
    , _bufSize    :: !Int                -- ^ how many bytes to buffer before commiting to sink
    , _name       :: !(Maybe Text)       -- ^ logger name
    , _nameMsg    :: !(Msg -> Msg)
    }

output :: Settings -> Output
output = _output

setOutput :: Output -> Settings -> Settings
setOutput x s = s { _output = x }

immFlush :: Settings -> Bool
immFlush = _immFlush

setImmFlush :: Bool -> Settings -> Settings
setImmFlush x s = s { _immFlush = x }

-- | The time and date format used for the timestamp part of a log line.
format :: Settings -> Maybe DateFormat
format = _format

setFormat :: Maybe DateFormat -> Settings -> Settings
setFormat x s = s { _format = x }

bufSize :: Settings -> Int
bufSize = _bufSize

setBufSize :: Int -> Settings -> Settings
setBufSize x s = s { _bufSize = max 1 x }

-- | Delimiter string which separates log line parts.
delimiter :: Settings -> ByteString
delimiter = _delimiter

setDelimiter :: ByteString -> Settings -> Settings
setDelimiter x s = s { _delimiter = x }

color :: Settings -> Bool
color = _color

setColor :: Bool -> Settings -> Settings
setColor x s = s { _color = x }

-- | Whether to use <http://cr.yp.to/proto/netstrings.txt netstring>
-- encoding for log lines.
netstrings :: Settings -> Bool
netstrings = _netstrings

setNetStrings :: Bool -> Settings -> Settings
setNetStrings x s = s { _netstrings = x }

logLevel :: Settings -> Level
logLevel = _logLevel

setLogLevel :: Level -> Settings -> Settings
setLogLevel x s = s { _logLevel = x }

-- | Log level of some named logger.
logLevelOf :: Text -> Settings -> Maybe Level
logLevelOf x s = Map.lookup x (_levelMap s)

logLevelMap :: Settings -> Map Text Level
logLevelMap = _levelMap

-- | Specify a log level for the given named logger. When a logger is
-- 'clone'd and given a name, the 'logLevel' of the cloned logger will be
-- the provided here.
setLogLevelOf :: Text -> Level -> Settings -> Settings
setLogLevelOf n x s = s { _levelMap = Map.insert n x (_levelMap s) }

setLogLevelMap :: Map Text Level -> Settings -> Settings
setLogLevelMap x s = s { _levelMap = x }

name :: Settings -> Maybe Text
name = _name

setName :: Maybe Text -> Settings -> Settings
setName Nothing   s = s { _name = Nothing, _nameMsg = id }
setName (Just xs) s = s { _name = Just xs, _nameMsg = msg xs }

nameMsg :: Settings -> (Msg -> Msg)
nameMsg = _nameMsg

setNameMsg :: (Msg -> Msg) -> Settings -> Settings
setNameMsg x s = s { _nameMsg = x }

data Level
    = Trace
    | Debug
    | Info
    | Warn
    | Error
    | Fatal
    deriving (Eq, Ord, Read, Show)

data Output
    = StdOut
    | StdErr
    | Path FilePath
    deriving (Eq, Ord, Show)

newtype DateFormat = DateFormat
    { display :: UnixTime -> ByteString
    }

instance IsString DateFormat where
    fromString = DateFormat . formatUnixTimeGMT . pack

-- | ISO 8601 date-time format.
iso8601UTC :: DateFormat
iso8601UTC = "%Y-%0m-%0dT%0H:%0M:%0SZ"

-- | Default settings:
--
--   * 'logLevel'   = 'Debug'
--
--   * 'output'     = 'StdOut'
--
--   * 'format'     = 'iso8601UTC'
--
--   * 'delimiter'  = \", \"
--
--   * 'netstrings' = False
--
--   * 'bufSize'    = 'FL.defaultBufSize'
--
--   * 'name'       = Nothing
--
defSettings :: Settings
defSettings = Settings
    Debug
    Map.empty
    StdOut
    False
    (Just iso8601UTC)
    ", "
    True
    False
    defaultBufSize
    Nothing
    id
