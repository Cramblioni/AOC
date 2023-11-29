module Main where
import Data.Char (isDigit)
main = interact solution2
infixr 9 ...
(...) = (.).(.)
s a b c = a c ( b c )
---------------------------------- SOLUTION 1 ---------------------------------
data Game = Game Int [Colour] deriving (Show)
type Colour = (Int, Int, Int)
valid (r, g, b) (gr, gg, gb) = and [gr <= r, gg <= g, gb <= b]
validGame cond (Game _ gs) = and $ map (valid cond) gs

mixup (r1, g1, b1) (r2, g2, b2) = (r1 + r2, g1 + g2, b1 + b2)
-- parsing functions
--      I'm going to cheat by making something bespoke
item :: String -> Colour
-- item body = error $ "got \"" ++ body ++ "\" lol"
item body = let (num, (_:col)) = span isDigit body in classif col (read num)
    where classif "red"   x = (x, 0, 0)
          classif "green" x = (0, x, 0)
          classif "blue"  x = (0, 0, x)
          classif x       _ = error ("got \"" ++ show x ++ "\" lol") 

split :: String -> String -> [String]
split cond = accum []
    where probe :: String -> String -> Maybe String
          probe [] xs = Just xs
          probe _ []  = Nothing
          probe (x:xs) (y:ys) = if x == y then probe xs ys else Nothing
          accum :: String -> String -> [String]
          -- accumulate, then handoff and then combine
          accum acc [] = [reverse acc]
          accum acc (x:xs) = case probe cond (x:xs) of
                Just cont -> reverse acc : accum [] cont
                Nothing   -> accum (x:acc) xs

sublist = foldr1 mixup . map item . split ", "
list    = map sublist . split "; "

parseGame = s (Game . getId) (list . drop 2 . snd . span (/=':'))
    where getId = read . drop (length "Game ") . fst . span (/=':')

ids (Game x _) = x
validate :: Colour -> [Game] -> Int
validate =  sum ... map ids ... filter . validGame
condit = (12, 13, 14)
solution1 = show . validate condit . map parseGame . lines
---------------------------------- SOLUTION 2 ---------------------------------

minreq :: Game -> Colour
minreq (Game _ cols) = foldr1 miniq cols
    where miniq (r1, g1, b1) (r2, g2, b2) = (max r1 r2, max g1 g2, max b1 b2)

power :: Colour -> Int
power (r, g, b) = max r 1 * max g 1 * max b 1

magic :: Game -> Int
magic = power . minreq

solution2 = show . sum . map (magic . parseGame) . lines
