module Eval1
  ( eval
  , State
  )
where

import           AST
import qualified Data.Map.Strict               as M
import           Data.Strict.Tuple

-- Estados
type State = M.Map Variable Int

-- Estado vacío
initState :: State
initState = M.empty

-- Busca el valor de una variable en un estado
lookfor :: Variable -> State -> Int
lookfor v s = case M.lookup v s of
                Nothing -> error "ERROR: key not found"
                Just n  -> n

-- Cambia el valor de una variable en un estado
update :: Variable -> Int -> State -> State
update = M.insert  

-- Evalúa un programa en el estado vacío
eval :: Comm -> State
eval p = stepCommStar p initState

-- Evalúa múltiples pasos de un comando en un estado,
-- hasta alcanzar un Skip
stepCommStar :: Comm -> State -> State
stepCommStar Skip s = s
stepCommStar c    s = Data.Strict.Tuple.uncurry stepCommStar $ stepComm c s

-- Evalúa un paso de un comando en un estado dado
stepComm :: Comm -> State -> Pair Comm State
stepComm (Let v e)            s = (Skip :!: update v n s') where (n :!: s') = (evalExp e s)
stepComm (Seq Skip c1)        s = (c1 :!: s)   
stepComm (Seq c0 c1)          s = let (c0':!: s') = stepComm c0 s 
                                  in  ((Seq c0' c1) :!: s')
stepComm (IfThenElse b c0 c1) s = let (b' :!: s') = evalExp b s
                                  in  if b' then  (c0 :!: s') else (c1 :!: s')
stepComm (RepeatUntil c b)    s = (Seq c c' :!: s)
                                  where c' = (IfThenElse b Skip (RepeatUntil c b)) 

-- Evalúa una expresión
evalExp :: Exp a -> State -> Pair a State
evalExp (Const n) s = n :!: s
evalExp (Var x)   s = lookfor x s :!: s
evalExp (UMinus e) s = let (n :!: s') = evalExp e s
                       in (-n :!: s')
evalExp (Plus e0 e1) s = let (n0 :!: s') = evalExp e0 s
                             (n1 :!: s'') = evalExp e1 s'
                         in (n0 + n1 :!: s'')
evalExp (Minus e0 e1) s = let (n0 :!: s') = evalExp e0 s
                              (n1 :!: s'') = evalExp e1 s'
                          in (n0 - n1 :!: s'')
evalExp (Times e0 e1) s = let (n0 :!: s') = evalExp e0 s
                              (n1 :!: s'') = evalExp e1 s'
                          in (n0 * n1 :!: s'')
evalExp (Div e0 e1) s = let (n0 :!: s') = evalExp e0 s
                            (n1 :!: s'') = evalExp e1 s'
                        in (n0 `div` n1 :!: s'')

evalExp (VarInc x) s = let x' = lookfor x s + 1
                       in (x' :!: (update x x' s))

evalExp (VarDec x) s = let x' = lookfor x s - 1
                       in (x' :!: (update x x' s))
evalExp BTrue  s = (True :!: s)         
evalExp BFalse s = (False :!: s)         

evalExp (Lt e0 e1) s = let (n0 :!: s') = evalExp e0 s
                           (n1 :!: s'') = evalExp e1 s'
                       in (n0 < n1 :!: s'')
evalExp (Gt e0 e1) s = let (n0 :!: s') = evalExp e0 s
                           (n1 :!: s'') = evalExp e1 s'
                       in (n0 > n1 :!: s'')


evalExp (And p0 p1) s = let (b0 :!: s') = evalExp p0 s
                            (b1 :!: s'') = evalExp p1 s'
                        in  (b0 && b1 :!: s'')

evalExp (Or p0 p1) s = let (b0 :!: s') = evalExp p0 s
                           (b1 :!: s'') = evalExp p1 s'
                       in  ((b0 || b1) :!: s'')

evalExp (Not p) s = let (b :!: s') = evalExp p s
                    in (not b :!: s')
evalExp (Eq e0 e1) s = let (n0 :!: s') = evalExp e0 s
                           (n1 :!: s'') = evalExp e1 s'
                       in (n0 == n1 :!: s'')
evalExp (NEq e0 e1) s = let (n0 :!: s') = evalExp e0 s
                            (n1 :!: s'') = evalExp e1 s'
                        in (n0 /= n1 :!: s'')

prog = Seq (Seq (Let "n" (Const 25)) 
                    (Let "i" (UMinus (Const 1)))) 
               (RepeatUntil (Seq (Let "i" (Plus (Var "i") (Const 1))) (Let "t" (Times (Var "i") (Var "i")))) 
                            (Or (Gt (Var "t") (Var "n")) (Eq (Var "t") (Var "n"))))
