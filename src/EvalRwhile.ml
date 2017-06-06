open AbsRwhile
open PrintRwhile
open List

let proc_list = ref []

type store = (rIdent * valT) list

let vtrue = VCons (VNil, VNil)
let vfalse = VNil

let prtStore (i : int) (e : (rIdent * valT) list) : doc = 
  let rec f = function
    | [] -> concatD []
    | [(x,v)] -> concatD [prtRIdent 0 x; render ":="; prtValT 0 v]
    | (x,v) :: ss -> concatD [prtRIdent 0 x; render ":="; prtValT 0 v; render "," ; f ss]
  in concatD [render "{"; f e; render "}"]

(* リストに要素を追加する。ただし、すでにその要素がリストにある場合は追加しない。 *)
let rec insert x : 'a list -> 'a list = function 
  | [] -> [x]
  | y :: ys -> y :: if x = y then ys else insert x ys

let merge xs ys = fold_right insert xs ys

(* Reversible update *)
let rec rupdate (x, vx) = function
  | [] -> failwith ("Variable " ^ printTree prtRIdent x ^ " is not found (1)")
  | (y, vy) :: ys -> if x = y 
		     then (if vy = VNil 
			   then (y, vx)
			   else if vx = vy 
			   then (y, VNil)
			   else if vx = VNil
			   then (y, vy)
			   else failwith "error in update") :: ys
		     else (y, vy) :: rupdate (x, vx) ys

(* Irreversible update *)
let rec update (x, vx) = function
  | [] -> failwith ("Variable " ^ printTree prtRIdent x ^ " is not found (2)")
  | (y, vy) :: ys -> if x = y
		     then (y, vx) :: ys
		     else (y, vy) :: update (x, vx) ys

let all_cleared (s : store) = for_all (fun (_, v) -> v = VNil) s

let rec varExp : exp -> rIdent list = function
  | EAnd (e1, e2) -> merge (varExp e1) (varExp e2)
  | ECons (e1, e2) -> merge (varExp e1) (varExp e2)
  | EHd e -> varExp e
  | ETl e -> varExp e
  | EEq (e1, e2) -> merge (varExp e1) (varExp e2)
  | EVar (Var x) -> [x]
  | EVal v -> []

(* プログラム中に使用されている変数名を列挙する。 *)
let rec varPat : pat -> rIdent list = function
   PCons (q,r) -> merge (varPat q) (varPat r)
 | PVar (Var x) -> [x]
 | PAtom _ -> []
 | PNil  -> []
 | PCall (x,pat) -> varPat pat

let rec varCom : com -> rIdent list = function
  | CAsn (x,e) -> insert x (varExp e)
  | CRep (q, r) -> merge (varPat q) (varPat r)
  | CCond (e, thenBranch, elseBranch, f) ->
     fold_right merge [varExp e; varExp f; varThenBranch thenBranch; varElseBranch elseBranch] []
  | CLoop (e, doBranch, loopBranch, f) ->
     fold_right merge [varExp e; varExp f; varDoBranch doBranch; varLoopBranch loopBranch] []
  | CShow _ -> []

and varThenBranch = function
  | BThen cs  -> List.concat (List.map varCom cs)
  | BThenNone -> []

and varElseBranch = function
  | BElse cs  -> List.concat (List.map varCom cs)
  | BElseNone -> []

and varDoBranch = function
  | BDo cs  -> List.concat (List.map varCom cs)
  | BDoNone -> []

and varLoopBranch = function
  | BLoop cs  -> List.concat (List.map varCom cs)
  | BLoopNone -> []

let varProc (Proc (name, x, c, y)) : rIdent list =
  merge (varPat x) (merge (varPat y) (fold_right merge (List.map varCom c) []))

let rec varProgram (Prog ps) = fold_right merge (List.map varProc ps) []

(* Evaluation *)
let evalVariable s (Var x) =
  try
    assoc x s
  with Not_found ->
    print_endline ("evalVariable: " ^ printTree prtStore s ^ "\n" ^ printTree prtVariable (Var x));
    raise Not_found

let rec evalExp s = function
    ECons (e1, e2) -> VCons (evalExp s e1, evalExp s e2)
  | EHd e -> (match evalExp s e with
	      | VNil | VAtom _ as v -> failwith ("No head. Expression " ^ printTree prtExp (EHd e) ^ " has value " ^ printTree prtValT v)
	      | VCons (v,_) -> v)
  | ETl e -> (match evalExp s e with
	      | VNil | VAtom _ as v -> failwith ("No tail. Expression " ^ printTree prtExp (ETl e) ^ " has value " ^ printTree prtValT v)
	      | VCons (_,v) -> v)
  | EAnd (e1, e2) -> if evalExp s e1 = vtrue && evalExp s e2 = vtrue then vtrue else vfalse
  | EEq (e1, e2) -> if evalExp s e1 = evalExp s e2 then vtrue else vfalse
  | EVar x -> evalVariable s x
  | EVal v -> v

and evalPat s p = match p with
    PCons (q, r) -> let (s1, d1) = evalPat s q in
		    let (s2, d2) = evalPat s1 r in
		    (s2, VCons (d1, d2))
  | PVar (Var y) -> let v = evalVariable s (Var y) in
		    (update (y,VNil) s, v)
  | PNil -> (s, VNil)
  | PAtom x -> (s, VAtom x)
  | PCall (name,arg) -> let (s',v) = evalPat s arg in
                        let aproc = 
                          try
                            find (fun (Proc (name',_,_,_)) -> name = name') (!proc_list)
                          with Not_found ->
                            print_endline ("procedure " ^ printTree prtRIdent name ^ " not found");
                            raise Not_found
                        in
                        (s',evalProgram (Prog (aproc :: !proc_list)) v)

and inv_evalPat s (p,v) = match (p,v) with
    (PCons (p1, p2), VCons (v1, v2)) -> let s1 = inv_evalPat s (p1, v1) in
					inv_evalPat s1 (p2, v2)
  | (PVar (Var y), v) -> if evalVariable s (Var y) = VNil
			 then update (y, v) s
			 else (print_string ("impossible happened in inv_evalPat.PVar\n" ^
					       "pattern: " ^ printTree prtPat p ^ "\n" ^
						 "term: " ^ printTree prtValT v ^ "\n" ^
						   "store: " ^ printTree prtStore s ^ "\n");
			       failwith "in inv_evalPat.PVar"
			      )
  | (PNil, VNil) -> s
  | (PAtom x, VAtom y) -> if x = y then s
		          else failwith ("Pattern matching failed.\n" ^
				           printTree prtPat (PAtom x) ^ " and " ^ printTree prtValT (VAtom y) ^ " are not equal (in inv_evalPat)\n" ^
				             printTree prtStore s ^ "\n")
  | (PCons _ as p, v) -> failwith ("impossible happened in inv_evalPat.PCons\n" ^
				     "pattern: " ^ printTree prtPat p ^ "\n" ^
				       "term: " ^ printTree prtValT v ^ "\n" ^
					 "store: " ^ printTree prtStore s ^ "\n"
				  )
  | (PCall (name,arg), v) -> failwith "ok"
  | _ -> failwith "not matched"

and evalComs (s : store) cs = match cs with
    []     -> s
  | c::cs' -> let s' = evalCom s c in evalComs s' cs'

and evalCom (s : store) : com -> store = function
  | CAsn (y, e) -> let v' = evalExp s e in
		   rupdate (y, v') s
  | CRep (q, r) -> let (s1, v1) = evalPat s r in
		   inv_evalPat s1 (q, v1)
  | CCond (e, thenbranch, elsebranch, f) ->
     if evalExp s e = vtrue then
       let s1 = (match thenbranch with
		 | BThen cs  -> evalComs s cs
		 | BThenNone -> s)
       in
       if evalExp s1 f = vtrue then s1
       else failwith ("Assertion " ^ printTree prtExp f ^ " is not true.\n")
     else
       let s1 = match elsebranch with
	 | BElse cs  -> evalComs s cs
	 | BElseNone -> s
       in
       if evalExp s1 f = vfalse then s1
       else failwith ("Assertion " ^ printTree prtExp f ^ " is not false.\n")
  | CLoop (e, dobranch, loopbranch, f) ->
     if evalExp s e = vtrue then
       let s1 = match dobranch with
	   BDo cs -> evalComs s cs
	 | BDoNone -> s
       in
       evalLoop s1 (e, dobranch, loopbranch, f)
     else failwith ("Assertion " ^ printTree prtExp e ^ " is not true.\n")
  | CShow e -> (print_string (printTree prtExp e ^ " = " ^ printTree prtValT (evalExp s e) ^ "\n"); s)

and evalLoop (s : store) (e, dobranch, loopbranch, f) : store =
  if evalExp s f = VCons (VNil, VNil)
  then s
  else
    let s1 = (match loopbranch with
	 	BLoop cs  -> evalComs s cs
	      | BLoopNone -> s)
    in
    assert (evalExp s1 e = VNil);
    let s2 = (match dobranch with
		BDo cs  -> evalComs s1 cs
	      | BDoNone -> s1)
    in
    evalLoop s2 (e, dobranch, loopbranch, f)

and evalProgram (Prog prog : program) (v : valT): valT =
  match prog with
    [] -> failwith "no procedure"
  | p :: ps ->
    let Proc (name, x, cs, y) = p in
    proc_list := (p :: ps);
    let s = List.map (fun x -> (x, VNil)) (varProc p) in
    let s1 = inv_evalPat s (x,v) in
    let s2 = evalComs s1 cs in
    let (s3,res) = evalPat s2 y in
    if all_cleared s3 then res
    else failwith ("Some variables are not nil.\n" ^ printTree prtStore s3)


    (*
    and evalProc (s : store) (Proc (name, x, cs, y)) v =
  let s1 = inv_evalPat s (x,v) in
  print_endline "here2"; 
  let s2 = evalComs s1 cs in
  print_endline "here3"; 
  let (s3,res) = evalPat s2 y in
  if all_cleared s3 then res
  else failwith ("Some variables are not nil.\n" ^ printTree prtStore s3)

and evalProgram (Prog (p :: ps) : program) (v : valT): valT =
  let s = List.map (fun x -> (x, VNil)) (varProc p) in
  (proc_list := (p::ps); evalProc s p v)
     *)
