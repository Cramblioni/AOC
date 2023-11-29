module Main where
import Data.Char (isDigit)


infixr 9 ...
(...) = (.).(.)
phoenix a b c d = a (b d) (c d)

main = interact $ solution2
--------------------------------- SOLUTION 1 -----------------------------------

-- Idea: 2 phases
--      - one to get a list of numbers && bounding boxes
--      - One to get a list of symbol positions

type Point = (Int, Int)
type Run = (Point, Int)

enumerate = inner 0
    where inner _ []     = []
          inner x (y:ys) = (x, y) : inner (x + 1) ys
symbols :: String -> [Point]
symbols = foldl (++) [] . map (uncurry (schloop 0)) . enumerate . lines
    where schloop _ _ [] = []
          schloop x y (c:cs) | isDigit c || c == '.' = schloop (x + 1) y cs
                             | otherwise = (x, y) : schloop (x + 1) y cs

near :: Point -> Point -> Bool
near (x1, y1) (x2, y2) = abs (x1 - x2) <= 1 && abs (y1 - y2) <= 1

along :: Run -> [Point]
along (_, 0) = []
along ((x, y), l) = (x, y) : along ((x + 1, y), l - 1)

nearRun :: Run -> Point -> Bool
---- we can use: or ... _ . (map (flip near) . along)
---- but we need to fill the hole
---- the hole looks a bit like: map . flip ($)
-- nearRun = or ... flip map . near . along
nearRun run point = or $ map (near point) (along run)

numbera :: String -> [(Run, Int)]
numbera = foldl (++) [] . map (uncurry (schloop 0)) . enumerate . lines
    where 
          schloop _ _ [] = []
          schloop x y (c:cs) | isDigit c = schlurp (x,y) 1 [c] cs
                             | otherwise = schloop (x+1) y    cs
          schlurp p l acc [] = [((p, l), read . reverse $ acc)]
          schlurp p l acc (c:cs) | isDigit c = schlurp p (l + 1) (c:acc) cs
                                 | otherwise = ((p, l), read . reverse $ acc)
                                             : let (x, y) = p
                                               in schloop (x + l) y (c:cs) 


solution1 = show . sum . map snd . phoenix (filter . validi) symbols numbera
-- solution1 = show . snd . head . drop 1 . numbera
-- solution1 = unlines . map show . numbera
validi many (oth, _) = or (map (nearRun oth) many)
--------------------------------- SOLUTION 2 -----------------------------------

gears :: String -> [Point]
gears = foldl (++) [] . map (uncurry (schloop 0)) . enumerate . lines
    where schloop _ _ [] = []
          schloop x y (c:cs) | c == '*'  = (x, y) : schloop (x + 1) y cs
                             | otherwise = schloop (x + 1) y cs


solution2 = show . sum . phoenix (map . subble) numbera gears
    where subble nums gear = wub . map snd . filter (flip (nearRun . fst) gear) $ nums
          wub [x, y] = x * y
          wub _      = 0
