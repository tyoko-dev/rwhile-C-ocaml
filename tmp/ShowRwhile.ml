(* show functions generated by the BNF converter *)

open AbsRwhile

(* use string buffers for efficient string concatenations *)
type showable = Buffer.t -> unit

let show (s : showable) : string = 
    let init_size = 16 in (* you may want to adjust this *)
    let b = Buffer.create init_size in
    s b;
    Buffer.contents b
    
let emptyS : showable = fun buf -> ()

let c2s (c:char) : showable = fun buf -> Buffer.add_char buf c
let s2s (s:string) : showable = fun buf -> Buffer.add_string buf s

let ( >> ) (s1 : showable) (s2 : showable) : showable = fun buf -> s1 buf; s2 buf

let showChar (c:char) : showable = fun buf -> 
    Buffer.add_string buf ("'" ^ Char.escaped c ^ "'")

let showString (s:string) : showable = fun buf -> 
    Buffer.add_string buf ("\"" ^ String.escaped s ^ "\"")

let showList (showFun : 'a -> showable) (xs : 'a list) : showable = fun buf -> 
    let rec f ys = match ys with
        [] -> ()
      | [y] -> showFun y buf
      | y::ys -> showFun y buf; Buffer.add_string buf "; "; f ys 
    in
        Buffer.add_char buf '[';
        f xs;
        Buffer.add_char buf ']'


let showInt (i:int) : showable = s2s (string_of_int i)
let showFloat (f:float) : showable = s2s (string_of_float f)

let rec showRIdent (RIdent i) : showable = s2s "RIdent " >> showString i

let rec showAtom (Atom i) : showable = s2s "Atom " >> showString i


let rec showProgram (e:program) : showable = match e with
       Prog procs -> s2s "Prog" >> c2s ' ' >> c2s '(' >> showList showProc procs >> c2s ')'


and showProc (e:proc) : showable = match e with
       Proc (rident0, rident1, com, rident) -> s2s "Proc" >> c2s ' ' >> c2s '(' >> showRIdent rident0  >> s2s ", " >>  showRIdent rident1  >> s2s ", " >>  showCom com  >> s2s ", " >>  showRIdent rident >> c2s ')'


and showCom (e:com) : showable = match e with
       CSeq (com0, com) -> s2s "CSeq" >> c2s ' ' >> c2s '(' >> showCom com0  >> s2s ", " >>  showCom com >> c2s ')'
  |    CAsn (rident, exp) -> s2s "CAsn" >> c2s ' ' >> c2s '(' >> showRIdent rident  >> s2s ", " >>  showExp exp >> c2s ')'
  |    CRep (pat0, pat) -> s2s "CRep" >> c2s ' ' >> c2s '(' >> showPat pat0  >> s2s ", " >>  showPat pat >> c2s ')'
  |    CCond (exp0, thenbranch, elsebranch, exp) -> s2s "CCond" >> c2s ' ' >> c2s '(' >> showExp exp0  >> s2s ", " >>  showThenBranch thenbranch  >> s2s ", " >>  showElseBranch elsebranch  >> s2s ", " >>  showExp exp >> c2s ')'
  |    CLoop (exp0, dobranch, loopbranch, exp) -> s2s "CLoop" >> c2s ' ' >> c2s '(' >> showExp exp0  >> s2s ", " >>  showDoBranch dobranch  >> s2s ", " >>  showLoopBranch loopbranch  >> s2s ", " >>  showExp exp >> c2s ')'
  |    CShow exp -> s2s "CShow" >> c2s ' ' >> c2s '(' >> showExp exp >> c2s ')'


and showThenBranch (e:thenBranch) : showable = match e with
       BThen com -> s2s "BThen" >> c2s ' ' >> c2s '(' >> showCom com >> c2s ')'
  |    BThenNone  -> s2s "BThenNone" 


and showElseBranch (e:elseBranch) : showable = match e with
       BElse com -> s2s "BElse" >> c2s ' ' >> c2s '(' >> showCom com >> c2s ')'
  |    BElseNone  -> s2s "BElseNone" 


and showDoBranch (e:doBranch) : showable = match e with
       BDo com -> s2s "BDo" >> c2s ' ' >> c2s '(' >> showCom com >> c2s ')'
  |    BDoNone  -> s2s "BDoNone" 


and showLoopBranch (e:loopBranch) : showable = match e with
       BLoop com -> s2s "BLoop" >> c2s ' ' >> c2s '(' >> showCom com >> c2s ')'
  |    BLoopNone  -> s2s "BLoopNone" 


and showExp (e:exp) : showable = match e with
       ECons (exp0, exp) -> s2s "ECons" >> c2s ' ' >> c2s '(' >> showExp exp0  >> s2s ", " >>  showExp exp >> c2s ')'
  |    EHd exp -> s2s "EHd" >> c2s ' ' >> c2s '(' >> showExp exp >> c2s ')'
  |    ETl exp -> s2s "ETl" >> c2s ' ' >> c2s '(' >> showExp exp >> c2s ')'
  |    EEq (exp0, exp) -> s2s "EEq" >> c2s ' ' >> c2s '(' >> showExp exp0  >> s2s ", " >>  showExp exp >> c2s ')'
  |    EVar variable -> s2s "EVar" >> c2s ' ' >> c2s '(' >> showVariable variable >> c2s ')'
  |    EVal val' -> s2s "EVal" >> c2s ' ' >> c2s '(' >> showValT val' >> c2s ')'


and showPat (e:pat) : showable = match e with
       PCons (pat0, pat) -> s2s "PCons" >> c2s ' ' >> c2s '(' >> showPat pat0  >> s2s ", " >>  showPat pat >> c2s ')'
  |    PVar variable -> s2s "PVar" >> c2s ' ' >> c2s '(' >> showVariable variable >> c2s ')'
  |    PVal val' -> s2s "PVal" >> c2s ' ' >> c2s '(' >> showValT val' >> c2s ')'
  |    PCall (rident0, rident) -> s2s "PCall" >> c2s ' ' >> c2s '(' >> showRIdent rident0  >> s2s ", " >>  showRIdent rident >> c2s ')'


and showValT (e:valT) : showable = match e with
       VNil  -> s2s "VNil" 
  |    VAtom atom -> s2s "VAtom" >> c2s ' ' >> c2s '(' >> showAtom atom >> c2s ')'
  |    VCons (val'0, val') -> s2s "VCons" >> c2s ' ' >> c2s '(' >> showValT val'0  >> s2s ", " >>  showValT val' >> c2s ')'


and showVariable (e:variable) : showable = match e with
       Var rident -> s2s "Var" >> c2s ' ' >> c2s '(' >> showRIdent rident >> c2s ')'



