/* This ocamlyacc file was machine-generated by the BNF converter */
%{
open AbsRwhile
open Lexing


%}

%token TOK_atom TOK_call TOK_cons TOK_do TOK_else TOK_eval TOK_fi TOK_from TOK_func TOK_hd TOK_if TOK_loop TOK_nil TOK_not TOK_proc TOK_return TOK_show TOK_then TOK_tl TOK_uncall TOK_until

%token SYMB1 /* ; */
%token SYMB2 /* ( */
%token SYMB3 /* ) */
%token SYMB4 /* ^= */
%token SYMB5 /* <= */
%token SYMB6 /* =? */
%token SYMB7 /* < */
%token SYMB8 /* > */
%token SYMB9 /* >= */
%token SYMB10 /* && */
%token SYMB11 /* || */
%token SYMB12 /* . */

%token TOK_EOF
%token <string> TOK_Ident
%token <string> TOK_String
%token <int> TOK_Integer
%token <float> TOK_Double
%token <char> TOK_Char
%token <string> TOK_RIdent
%token <string> TOK_Atom

%start pProgram pValT
%type <AbsRwhile.program> pProgram
%type <AbsRwhile.valT> pValT


%%
pProgram : program TOK_EOF { $1 }
  | error { raise (BNFC_Util.Parse_error (Parsing.symbol_start_pos (), Parsing.symbol_end_pos ())) };

pValT : valT TOK_EOF { $1 }
  | error { raise (BNFC_Util.Parse_error (Parsing.symbol_start_pos (), Parsing.symbol_end_pos ())) };


program : proc_list { Prog $1 } 
;

proc_list : /* empty */ { []  } 
  | proc { (fun x -> [x]) $1 }
  | proc SYMB1 proc_list { (fun (x,xs) -> x::xs) ($1, $3) }
;

proc : TOK_proc rIdent SYMB2 pat SYMB3 com_list TOK_return pat { Proc ($2, $4, (List.rev $6), $8) } 
  | TOK_func rIdent SYMB2 pat SYMB3 fexp { Func ($2, $4, $6) }
;

com : rIdent SYMB4 exp { CAsn ($1, $3) } 
  | pat SYMB5 pat { CRep ($1, $3) }
  | TOK_if exp thenBranch elseBranch TOK_fi exp { CCond ($2, $3, $4, $6) }
  | TOK_from exp doBranch loopBranch TOK_until exp { CLoop ($2, $3, $4, $6) }
  | TOK_show exp { CShow $2 }
;

com_list : /* empty */ { []  } 
  | com_list com SYMB1 { (fun (x,xs) -> x::xs) ($2, $1) }
;

thenBranch : TOK_then com_list { BThen (List.rev $2) } 
  | /* empty */ { BThenNone  }
;

elseBranch : TOK_else com_list { BElse (List.rev $2) } 
  | /* empty */ { BElseNone  }
;

doBranch : TOK_do com_list { BDo (List.rev $2) } 
  | /* empty */ { BDoNone  }
;

loopBranch : TOK_loop com_list { BLoop (List.rev $2) } 
  | /* empty */ { BLoopNone  }
;

fexp : TOK_if exp TOK_then fexp TOK_else fexp { FIf ($2, $4, $6) } 
  | TOK_return exp { Freturn $2 }
;

exp : TOK_not exp1 { ENot $2 } 
  | TOK_atom exp1 { EAtom $2 }
  | TOK_cons exp1 exp1 { ECons ($2, $3) }
  | TOK_hd exp1 { EHd $2 }
  | TOK_tl exp1 { ETl $2 }
  | TOK_eval rIdent SYMB2 exp SYMB3 { Ecall ($2, $4) }
  | SYMB6 exp1 exp1 { EEq ($2, $3) }
  | SYMB7 exp1 exp1 { ELt ($2, $3) }
  | SYMB5 exp1 exp1 { ELe ($2, $3) }
  | SYMB8 exp1 exp1 { EGt ($2, $3) }
  | SYMB9 exp1 exp1 { EGe ($2, $3) }
  | SYMB10 exp1 exp1 { EAnd ($2, $3) }
  | SYMB11 exp1 exp1 { EOr ($2, $3) }
  | exp1 {  $1 }
;

exp1 : variable { EVar $1 } 
  | valT { EVal $1 }
  | SYMB2 exp SYMB3 {  $2 }
;

pat : SYMB2 pat SYMB12 pat SYMB3 { PCons ($2, $4) } 
  | variable { PVar $1 }
  | atom { PAtom $1 }
  | TOK_nil { PNil  }
  | TOK_call rIdent SYMB2 pat SYMB3 { PCall ($2, $4) }
  | TOK_uncall rIdent SYMB2 pat SYMB3 { PUncall ($2, $4) }
;

valT : TOK_nil { VNil  } 
  | atom { VAtom $1 }
  | SYMB2 valT SYMB12 valT SYMB3 { VCons ($2, $4) }
;

variable : rIdent { Var $1 } 
;


rIdent : TOK_RIdent { RIdent ($1)};
atom : TOK_Atom { Atom ($1)};


