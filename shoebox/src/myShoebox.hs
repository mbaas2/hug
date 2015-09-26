{-# LANGUAGE OverloadedStrings #-}
module Shoebox where

import Data.Text (Text, splitOn)
import qualified Data.Map as M
import Data.Maybe
--import Data.List.Split (splitOn)

-- types of databases
type ShoeSegmentationDB = M.Map Text [MorphemeBreak]  -- segmentation
type ShoeLexiconDB = M.Map LexEl [Meaning]       -- base words, lexicon
type ShoeSuffixDB  = M.Map SuffixEl [Abbreviation] -- suffixes
type ShoePrefixDB  = M.Map PrefixEl [Abbreviation] -- prefixes

type SuffixEl = Text
type PrefixEl = Text
type Abbreviation = Text
type Meaning = Text
type LexEl  = Text  -- inside lexicon
type FullEl = Text -- full element
type Suffix = Text -- suffix
type Prefix = Text -- prefix
type TextEl = Text

newtype TextLine = TX TextEl
	deriving (Show, Eq)

newtype GlossLine = GL [GlossChoice]
	deriving (Show, Eq)

data GlossChoice = AbbreviationChoice [Abbreviation]
                 | MeaningChoice [Meaning]
  deriving (Show,Eq)

data Gloss = Abbreviation Abbreviation
           | Meaning Meaning
  deriving (Show,Eq)

newtype MorphemeBreak = MB [Morpheme]
  deriving (Show,Eq)

data Morpheme = MorphemeLex LexEl | MorphemeSuffix Suffix | MorphemePrefix Prefix
  deriving (Show,Eq)

data InterlinearBlock = ILB TextLine MorphemeBreak GlossLine
	deriving (Show,Eq)


shoeLexiconDB :: ShoeLexiconDB
shoeLexiconDB = M.fromList
  [ ("maison",["house", "building"])
   	, ("lorsque",["when"])
   	, ("avoir",["to_have"])
   	, ("six",["six"])
   	, ("an",["year"])
  ]

shoeSuffixDB :: ShoeSuffixDB
shoeSuffixDB = M.fromList
  [ ("s",["PL"])
  	, ("ais",["1sIPF"])
  ]

shoePrefixDB :: ShoePrefixDB
shoePrefixDB = M.fromList
  [ ("je",["1sPRON"])
  ]

shoeSegmentationDB :: ShoeSegmentationDB
shoeSegmentationDB = M.fromList
   [ ("maisons", [ MB [ MorphemeLex "maison"
                      , MorphemeSuffix "s"
                      ]
                 ]
     )
   , ("cadeaux", [ MB [ MorphemeLex "cadeau"
                      , MorphemeSuffix "s"
                      ]
                 ]
     )
   , ("j'avais", [ MB [ MorphemePrefix "je"
	 										, MorphemeLex "avoir"
                      , MorphemeSuffix "ais"
                      ]
                 ]
     )
   , ("ans", [ MB [ MorphemeLex "an"
                      , MorphemeSuffix "s"
                      ]
                 ]
     )
   ]

type ShoeDB = (ShoeLexiconDB, ShoeSuffixDB, ShoePrefixDB, ShoeSegmentationDB)

shoeDB :: ShoeDB
shoeDB = (shoeLexiconDB, shoeSuffixDB, shoePrefixDB, shoeSegmentationDB)

breakTX :: TextEl -> ShoeSegmentationDB -> [MorphemeBreak]
breakTX textEl segmentationDB =
  fromMaybe [MB [MorphemeLex textEl]]
    (M.lookup textEl segmentationDB)

lookupMB :: MorphemeBreak -> ShoeLexiconDB -> ShoeSuffixDB -> ShoePrefixDB -> [GlossChoice]
lookupMB (MB mbs) lexiconDB suffixDB prefixDB = map go mbs
  where
    go (MorphemeLex l)    = MeaningChoice $      fromMaybe [] (M.lookup l lexiconDB)
    go (MorphemeSuffix s) = AbbreviationChoice $ fromMaybe [] (M.lookup s suffixDB)
    go (MorphemePrefix p) = AbbreviationChoice $ fromMaybe [] (M.lookup p prefixDB)

gloss :: TextEl -> ShoeDB -> [InterlinearBlock]
gloss textEl (lexiconDB,suffixDB,prefixDB,segmentationDB) = do
  morphemeBreak <- breakTX textEl segmentationDB
  let glosses = GL (lookupMB morphemeBreak lexiconDB suffixDB prefixDB)
  return $ ILB (TX textEl) morphemeBreak glosses

intlx :: [TextEl] -> ShoeDB -> [[InterlinearBlock]]
intlx [] shoeDB = []
intlx (x:xs) shoeDB =  gloss x shoeDB : intlx xs shoeDB

intl :: Text -> ShoeDB -> [[InterlinearBlock]]
intl s shoeDB = intlx (splitOn " " s) shoeDB

