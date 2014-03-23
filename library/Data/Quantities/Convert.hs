module Data.Quantities.Convert where

import qualified Data.Map as M

import Data.Quantities.Data (Quantity(..), CompositeUnit, SimpleUnit(..), Definitions(..),
                             magnitude, units)


-- | Convert quantity to given units.
convert :: Quantity -> CompositeUnit -> Quantity
convert x u = Quantity mag u d
  where d = defs x
        mag = magnitude x * (baseFactor d (units x) / baseFactor d u)

-- | Like convert, but don't use quantity's definitions.
convert' :: Definitions -> Quantity -> CompositeUnit -> Quantity
convert' d x u = Quantity mag u d
  where mag = magnitude x * (baseFactor d (units x) / baseFactor d u)

-- | Factor to convert units to their base.
baseFactor :: Definitions -> CompositeUnit -> Double
baseFactor d = product . map (simpleBaseFactor d)

-- | Factor to convert single unit to base. Takes care of power and
-- prefix.
simpleBaseFactor :: Definitions -> SimpleUnit -> Double
simpleBaseFactor d (SimpleUnit sym pr pow) = fac ** pow
  where fac    = simpleBaseFactor' d sym * preVal
        preVal = prefixValues d M.! pr

-- | Conversion factor for unit symbol to base.
simpleBaseFactor' :: Definitions -> String -> Double
simpleBaseFactor' d unit = conversions d M.! (unit, base)
  where base = bases d M.! unit

-- | Convert a quantity to its base units.
convertBase :: Quantity -> Quantity
convertBase x = convertBase' d x
  where d = defs x

-- | Like convertBase, but don't use quantity's definitions.
convertBase' :: Definitions -> Quantity -> Quantity
convertBase' d x = convert' d x $ baseUnits d (units x)

-- | Get the base units for given units.
baseUnits :: Definitions -> CompositeUnit -> CompositeUnit
baseUnits _ [] = []
baseUnits d (SimpleUnit s _ p : xs) = SimpleUnit base "" p : baseUnits d xs
  where base = bases d M.! s

-- convertSymbol :: Definitions -> String -> String -> Double
-- convertSymbol d from to = convertSymbolBase d from / convertSymbolBase d to
