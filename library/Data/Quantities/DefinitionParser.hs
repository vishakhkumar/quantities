-- | Uses parsec to parse definition lines.
module Data.Quantities.DefinitionParser where

import Control.Applicative ((<*))
import Text.ParserCombinators.Parsec

import Data.Quantities.Data
import Data.Quantities.ExprParser (parseMultExpr)

-- | Parse multiline string of definitions (say, from a file) into a
-- list of definitions.
parseDefinitions :: String -> [Definition]
parseDefinitions input = case parse parseDefinitions' "Input File Parser" input of
  Left err -> error (show err) >> []
  Right val -> val

-- | Parsec parser for definitions.
parseDefinitions' :: Parser [Definition]
parseDefinitions' = many parseDef <* eof

-- | Parse any definition line
parseDef :: Parser Definition
parseDef  = do
  _ <- spaces
  -- skipMany comment
  optional $ many $ char '\n'
  line <- try parseDefLine <|> try parseBaseLine <|> parsePrefixLine
  spaces
  -- skipMany comment
  optional $ many $ char '\n'
  return line

-- comment :: Parser String
-- comment = char '#' >> many (noneOf "\n")

-- | Custom eol parsec parser.
eol :: Parser Char
eol = char '\n'

-- | Parse a line containing unit definition
-- Ex: minute = 60 s = min
parseDefLine :: Parser Definition
parseDefLine = do
  (UnitDefinition s e []) <- parseUnitDef
  syns <- many (try parseSynonym)
  return $ UnitDefinition s e syns

-- | Parses a unit definition. Example: foot = 12 in = ft = feet
parseUnitDef :: Parser Definition
parseUnitDef = do
  sym   <- parseSymbol <* spaces <* char '='
  quant <- parseMultExpr
  spaces
  -- skipMany comment
  return $ UnitDefinition sym quant []

-- | Parses the synonyms at the end of a base or unit definition.
parseSynonym :: Parser Symbol
parseSynonym = spaces >> char '=' >> spaces >> parseSymbol <* spaces


-- | Parse line containing base definition.
-- Ex: meter = [length] = m
parseBaseLine :: Parser Definition
parseBaseLine = do
  (sym, f) <- parseBase
  syns <- many (try parseSynonym)
  return $ BaseDefinition sym f syns

-- | Parse the base of a base definition. Example: [length] -> length
parseBase :: Parser (Symbol, Symbol)
parseBase = do
  sym <- parseSymbol <* spaces <* char '='
  b <- spaces >> char '[' >> option "" parseSymbol <* char ']'
  spaces
  -- skipMany comment
  return (sym, b)

-- | Parse line containing prefix definition
-- Ex: milli- = 1e-3 = m-
parsePrefixLine :: Parser Definition
parsePrefixLine = do
  (p, f) <- parsePrefix
  syns <- many (try parsePrefixSynonym)
  return $ PrefixDefinition p f syns

-- | Parse the prefix part of a prefix definition. Example: yocto- -> yocto
parsePrefix :: Parser (Symbol, Double)
parsePrefix = do
  pre <- many1 letter <* char '-' <* spaces <* char '='
  facQuant <- spaces >> parseMultExpr
  spaces
  if null (units' facQuant) then
    return (pre, magnitude facQuant)
    else fail "No units allowed in prefix definitions"

-- | Parse the synonyms for a prefix definition.
parsePrefixSynonym :: Parser Symbol
parsePrefixSynonym = spaces >> char '=' >> spaces >> parseSymbol <* char '-' <* spaces


-- | Parse a symbol for a unit
parseSymbol :: Parser Symbol
parseSymbol = do
  letter' <- letter
  rest    <- many (alphaNum <|> char '_')
  return $ letter' : rest
