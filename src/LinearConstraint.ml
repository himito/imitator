(*****************************************************************
 *
 *                     IMITATOR II
 * 
 * Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
 * Author:        Etienne Andre
 * Created:       2010/03/04
 * Last modified: 2010/03/16 TEST TOTO
 *
 ****************************************************************)

(**************************************************)
(* Modules *)
(**************************************************)
(*open Apron   *)
(*open Lincons0*)

module Ppl = Ppl_ocaml
open Ppl

open Global
open Gmp.Z.Infixes

(**************************************************)
(* TYPES *)
(**************************************************)

type variable = int
type coef = NumConst.t

(*type linear_term = Linexpr0.t*)

(* For legacy reasons (rational coefficients in input),      *)
(* the linear_term is a generalization of the corresponding  *)
(* PPL data structure Ppl.linear_expression, using rationals *)
(* instead of integers. *)
type linear_term =
	  Var of variable
	| Coef of coef
	| Pl of linear_term * linear_term
	| Mi of linear_term * linear_term
	| Ti of coef * linear_term

type op =
	| Op_g
	| Op_ge
	| Op_eq

(*type linear_inequality = Lincons0.t*)
type linear_inequality = Ppl.linear_constraint

(*type linear_constraint = Polka.strict Polka.t Abstract0.t *)
type linear_constraint = Ppl.polyhedron

(* split a rational number into numerator and denominator *)
let split_q r = 
	let p = NumConst.get_num r in
	let q = NumConst.get_den r in
	p, q


(* In order to convert a linear_term (with rational coefficients) *)
(* to the corresponding PPL data structure, it is normalized such *)
(* that the only non-rational coefficient is outside the term:    *)
(* p/q * ( ax + by + c ) *)
let rec normalize_linear_term lt =
		match lt with
			| Var v -> Variable v, NumConst.one
			| Coef c -> (
				  let p = NumConst.get_num c in
				  let q = NumConst.get_den c in
				  Coefficient p, NumConst.numconst_of_zfrac Gmp.Z.one q )
			| Pl (lterm, rterm) -> (
					let lterm_norm, fl = normalize_linear_term lterm in
					let rterm_norm, fr = normalize_linear_term rterm in
					let pl = NumConst.get_num fl in
					let ql = NumConst.get_den fl in
					let pr = NumConst.get_num fr in
					let qr = NumConst.get_den fr in
					(Plus (Times (pl *! qr, lterm_norm), (Times (pr *! ql, rterm_norm)))),
					NumConst.numconst_of_zfrac Gmp.Z.one (ql *! qr))
			| Mi (lterm, rterm) -> (
					let lterm_norm, fl = normalize_linear_term lterm in
					let rterm_norm, fr = normalize_linear_term rterm in
					let pl = NumConst.get_num fl in
					let ql = NumConst.get_den fl in
					let pr = NumConst.get_num fr in
					let qr = NumConst.get_den fr in
					(Minus (Times (pl *! qr, lterm_norm), (Times (pr *! ql, rterm_norm)))),
					NumConst.numconst_of_zfrac Gmp.Z.one (ql *! qr))
			| Ti (fac, term) -> (
					let term_norm, r = normalize_linear_term term in
					let p = NumConst.get_num fac in
					let q = NumConst.get_den fac in
					term_norm, NumConst.mul r (NumConst.numconst_of_zfrac p q))				
					
	
(**************************************************)
(** Global variables *)
(**************************************************)

(* The manager *)
(*let manager = Polka.manager_alloc_strict ()*)

(* The number of integer dimensions *)
let int_dim = ref 0

(* The number of real dimensions *)
let real_dim = ref 0

(* Total number of dimensions *)
let total_dim = ref 0

let nb_dimensions () = !total_dim

(**************************************************)
(* Useful Functions *)
(**************************************************)

(** check the dimensionality of a polyhedron *)
let assert_dimensions poly =
	let ndim = ppl_Polyhedron_space_dimension poly in
	if not (ndim = !total_dim) then (
		print_error ("Polyhedron has too few dimensions (" ^ (string_of_int ndim) ^ " / " ^ (string_of_int !total_dim) ^ ")");
		raise (InternalError "Inconsistent polyhedron found")	
	)			 	

(**************************************************)
(** {2 Linear terms} *)
(**************************************************)

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Creation} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Create a linear term using a list of coef and variables, and a constant *)
(*let make_linear_term members coef =                          *)
(*	(* Convert the members *)                                  *)
(*	let members = List.map apron_coeff_dim_of_member members in*)
(*	(* Convert the coef *)                                     *)
(*	let coeff_option = apron_coeff_option_of_constant coef in  *)
(*		Linexpr0.of_list None members coeff_option               *)

let make_linear_term members coef =
	List.fold_left (fun term head ->
		let (c, v) = head in 
			if c = NumConst.one then
				Pl (Var v, term)
			else
				Pl ((Ti (c, Var v), term))
	)	(Coef coef) members

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Functions} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Add two linear terms *)
let add_linear_terms lt1 lt2 =
	Pl (lt1, lt2)


(*--------------------------------------------------*)
(* Evaluation *)
(*--------------------------------------------------*)

(** Evaluate a linear term with a function assigning a value to each variable. *)
let rec evaluate_linear_term valuation_function linear_term =
	match linear_term with
		| Coef c -> c
		| Var v -> (
			  try valuation_function v 
			  with _ -> raise(InternalError ("No value was found for variable " ^ (string_of_int v) ^ ", while trying to evaluate a linear term; this variable was probably not defined.")))
		| Pl (lterm, rterm) -> ( 
				let lval = evaluate_linear_term valuation_function rterm in
				let rval = evaluate_linear_term valuation_function lterm in
				NumConst.add lval rval)
		| Mi (lterm, rterm) -> (
				let lval = evaluate_linear_term valuation_function rterm in
				let rval = evaluate_linear_term valuation_function lterm in
				NumConst.sub lval rval)
		| Ti (fac, rterm) -> ( 
				let rval = evaluate_linear_term valuation_function rterm in
				NumConst.mul fac rval)


(** Evaluate a linear term (PPL) with a function assigning a value to each variable. *)
let rec evaluate_linear_term_ppl valuation_function linear_term =
	match linear_term with
		| Coefficient z -> NumConst.numconst_of_mpz z
		| Variable v -> (
			  try valuation_function v 
			  with _ -> raise(InternalError ("No value was found for variable " ^ (string_of_int v) ^ ", while trying to evaluate a linear term; this variable was probably not defined.")))
	  | Unary_Plus t -> evaluate_linear_term_ppl valuation_function t
		| Unary_Minus t -> NumConst.neg (evaluate_linear_term_ppl valuation_function t)
		| Plus (lterm, rterm) -> (
				let lval = evaluate_linear_term_ppl valuation_function lterm in
				let rval = evaluate_linear_term_ppl valuation_function rterm in
				NumConst.add lval rval)
	 | Minus (lterm, rterm) -> (
				let lval = evaluate_linear_term_ppl valuation_function lterm in
				let rval = evaluate_linear_term_ppl valuation_function rterm in
				NumConst.sub lval rval)
	 | Times (z, rterm) -> ( 
				let rval = evaluate_linear_term_ppl valuation_function rterm in
				NumConst.mul (NumConst.numconst_of_mpz z) rval)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Conversion to string} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

let string_of_coef = NumConst.string_of_numconst
let string_of_constant = NumConst.string_of_numconst


(** Convert a linear term into a string *)	
let rec string_of_linear_term names linear_term =
	match linear_term with
		| Coef c -> string_of_coef c
		| Var v -> names v
		| Pl (lterm, rterm) -> (
			  let lstr = string_of_linear_term names lterm in
				let rstr = string_of_linear_term names rterm in
				lstr ^ " + " ^ rstr )
		| Mi (lterm, rterm) -> (
			  let lstr = string_of_linear_term names lterm in
				let rstr = string_of_linear_term names rterm in
				lstr ^ " - (" ^ rstr ^ ")" )
		| Ti (fac, rterm) -> (
				let fstr = string_of_coef fac in
				let tstr = string_of_linear_term names rterm in
				match rterm with
					| Coef _ -> fstr ^ "*" ^ tstr
					| Var  _ -> fstr ^ "*" ^ tstr
					| _ -> fstr ^ " * (" ^ tstr ^ ")" ) 				


(** Convert a linear term (PPL) into a string *)								
let rec string_of_linear_term_ppl names linear_term =
	match linear_term with
		| Coefficient z -> Gmp.Z.string_from z
		| Variable v -> names v
		| Unary_Plus t -> string_of_linear_term_ppl names t
		| Unary_Minus t -> (
				let str = string_of_linear_term_ppl names t in
				"-(" ^ str ^ ")")
		| Plus (lterm, rterm) -> (
			  let lstr = string_of_linear_term_ppl names lterm in
				let rstr = string_of_linear_term_ppl names rterm in
				lstr ^ " + " ^ rstr )
		| Minus (lterm, rterm) -> (
			  let lstr = string_of_linear_term_ppl names lterm in
				let rstr = string_of_linear_term_ppl names rterm in
				lstr ^ " - (" ^ rstr ^ ")" )
		| Times (z, rterm) -> (
				let fstr = Gmp.Z.string_from z in
				let tstr = string_of_linear_term_ppl names rterm in
				if (Gmp.Z.equal z (Gmp.Z.one)) then
					tstr
				else 
					match rterm with
						| Coefficient _ -> fstr ^ "*" ^ tstr
						| Variable    _ -> fstr ^ "*" ^ tstr
						| _ -> fstr ^ " * (" ^ tstr ^ ")" ) 				
				

(**************************************************)
(** {2 Linear inequalities} *)
(**************************************************)

(************** TO DO : minimize inequalities as soon as they have been created / changed *)

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(* Functions *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Creation} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Create a linear inequality using a linear term and an operator *)
let make_linear_inequality linear_term op =
	let ppl_term, r = normalize_linear_term linear_term in
	let p = NumConst.get_num r in
	let lin_term = Times (p, ppl_term) in
	let zero_term = Coefficient Gmp.Z.zero in
	match op with
		| Op_g -> Greater_Than (lin_term, zero_term)
		| Op_ge -> Greater_Or_Equal (lin_term, zero_term)
		| Op_eq -> Equal (lin_term, zero_term)
	

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Functions} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** split a linear inequality into its two terms and the operator *)
let split_linear_inequality = function
	| Less_Than (lterm, rterm) -> lterm, rterm, Less_Than_RS
	| Less_Or_Equal (lterm, rterm) -> lterm, rterm, Less_Or_Equal_RS
	| Equal (lterm, rterm) -> lterm, rterm, Equal_RS
	| Greater_Than (lterm, rterm) -> lterm, rterm, Greater_Than_RS
	| Greater_Or_Equal (lterm, rterm) -> lterm, rterm, Greater_Or_Equal_RS
	
(** build a linear inequality from two terms and an operator *)
let build_linear_inequality lterm rterm op = 
	match op with
		| Less_Than_RS -> Less_Than (lterm, rterm)
		| Less_Or_Equal_RS -> Less_Or_Equal (lterm, rterm)
		| Equal_RS -> Equal (lterm, rterm)
		| Greater_Than_RS -> Greater_Than (lterm, rterm)
		| Greater_Or_Equal_RS -> Greater_Or_Equal (lterm, rterm)

(** get the NumConst operator for a ppl relation symbol *)
let relop_from_rs = function
	| Less_Than_RS -> NumConst.l
	| Less_Or_Equal_RS -> NumConst.le
	| Equal_RS -> NumConst.equal
	| Greater_Than_RS -> NumConst.g
	| Greater_Or_Equal_RS -> NumConst.ge

(** inverts a relation symbol, where '=' maps to '=' *)
let invert_rs = function
	| Less_Than_RS -> Greater_Than_RS
	| Less_Or_Equal_RS -> Greater_Or_Equal_RS 
	| Equal_RS -> Equal_RS
	| Greater_Than_RS -> Less_Than_RS
	| Greater_Or_Equal_RS -> Less_Or_Equal_RS 

let make_linear_inequality_ppl lterm op rterm =
	let ppl_lterm, cl = normalize_linear_term lterm in
	let ppl_rterm, cr = normalize_linear_term rterm in
	let pl = NumConst.get_num cl in
	let ql = NumConst.get_den cl in
	let pr = NumConst.get_num cr in
	let qr = NumConst.get_den cr in
	let sl = pl *! qr in
	let sr = pr *! ql in
	let new_lterm = Times (sl, ppl_lterm) in
	let new_rterm = Times (sr, ppl_rterm) in
	build_linear_inequality new_lterm new_rterm op

(** evaluate a linear inequality for a given valuation *)
let evaluate_linear_inequality valuation_function linear_inequality =
	let lterm, rterm, op = split_linear_inequality linear_inequality in
	(* evaluate both terms *)
	let lval = evaluate_linear_term_ppl valuation_function lterm in
	let rval = evaluate_linear_term_ppl valuation_function rterm in
	(* compare according to the relation symbol *)
	(relop_from_rs op) lval rval	

(*--------------------------------------------------*)
(* Pi0-compatibility *)
(*--------------------------------------------------*)

(** Check if a linear inequality is pi0-compatible *)
let is_pi0_compatible_inequality pi0 linear_inequality =
	evaluate_linear_inequality pi0 linear_inequality

(** Negate a linear inequality; for an equality, perform the pi0-compatible negation *)
let negate_wrt_pi0 pi0 linear_inequality = 
	match linear_inequality with
		| Less_Than (lterm, rterm) -> Greater_Or_Equal (lterm, rterm)
		| Less_Or_Equal (lterm, rterm) -> Greater_Than (lterm, rterm)
		| Greater_Than (lterm, rterm) -> Less_Or_Equal (lterm, rterm)
		| Greater_Or_Equal (lterm, rterm) -> Less_Than (lterm, rterm)
		| Equal (lterm, rterm) -> (
				(* perform the negation compatible with pi0 *)
				let lval = evaluate_linear_term_ppl pi0 lterm in
				let rval = evaluate_linear_term_ppl pi0 rterm in
				if NumConst.g lval rval then
					Greater_Than (lterm, rterm)
				else if NumConst.l lval rval then
					Less_Than (lterm, rterm)
				else(
					raise (InternalError "Trying to negate an equality already true w.r.t. pi0")
				)
			)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Conversion} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)				   	


let is_zero_coef = function
	| Coefficient c -> c =! Gmp.Z.zero
	| _ -> false


(** build a sum of two expressions; respects the case where one of the 
	  operands is zero *)
let compact_sum lexpr rexpr =
	if is_zero_coef lexpr then (
		rexpr
  ) else (
		if is_zero_coef rexpr then (
			lexpr
		) else (
			Plus (lexpr, rexpr)
		))

(** splits an expression into positive and negative part for pretty printing;
 	  an expression a-b is mapped to (a, b) *) 
let rec sign_split_expression = function
	| Coefficient c ->
		if c <! Gmp.Z.zero then (
			(Coefficient Gmp.Z.zero, Coefficient (Gmp.Z.neg c))
		) else (
			(Coefficient c, Coefficient Gmp.Z.zero)
		)
	| Variable v -> (Variable v, Coefficient Gmp.Z.zero)
	| Unary_Plus expr -> sign_split_expression expr
	| Unary_Minus expr ->
		let pos, neg = sign_split_expression expr in (neg, pos)
	| Plus (lexpr, rexpr) -> 
		let lpos, lneg = sign_split_expression lexpr in
		let rpos, rneg = sign_split_expression rexpr in
		let new_pos = compact_sum lpos rpos in 
		let new_neg = compact_sum lneg rneg in 
		(new_pos, new_neg)
	| Minus (lexpr, rexpr) -> 
		sign_split_expression (Plus (lexpr, Unary_Minus rexpr))
	| Times (c, expr) -> 
		let pos, neg = sign_split_expression expr in
		let invert = c <! Gmp.Z.zero in
		let new_c = if invert then Gmp.Z.neg c else c in
		if new_c =! Gmp.Z.one then (
			if invert then (neg, pos) else (pos, neg)
		) else (
			let new_pos = if is_zero_coef pos then Coefficient Gmp.Z.zero else Times (new_c, pos) in
			let new_neg = if is_zero_coef neg then Coefficient Gmp.Z.zero else Times (new_c, neg) in
			if invert then (new_neg, new_pos) else (new_pos, new_neg)
		)			


(** normalize an inequality for pretty printing; *)
(** the expressions are rearranged such that only posistive coefficients occur *)
let normalize_inequality ineq = 
	let lterm, rterm, op = split_linear_inequality ineq in
	let lpos, lneg = sign_split_expression lterm in
	let rpos, rneg = sign_split_expression rterm in
	let lnew = compact_sum lpos rneg in
	let rnew = compact_sum rpos lneg in
	build_linear_inequality lnew rnew op


(** Convert a linear inequality into a string *)
let string_of_linear_inequality names linear_inequality =
	let normal_ineq = normalize_inequality linear_inequality in
	let lterm, rterm, op = split_linear_inequality normal_ineq in
	let lstr = string_of_linear_term_ppl names lterm in
	let rstr = string_of_linear_term_ppl names rterm in	
	let opstr = match op with
		| Less_Than_RS -> " < "
		| Less_Or_Equal_RS -> " <= "
		| Equal_RS -> " = "
		| Greater_Than_RS -> " > "
		| Greater_Or_Equal_RS -> " >= " in
	lstr ^ opstr ^ rstr

(**************************************************)
(** {2 Linear Constraints} *)
(**************************************************)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Creation} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

let copy constr =
	let poly = ppl_new_NNC_Polyhedron_from_NNC_Polyhedron constr in
	assert_dimensions poly;
  poly
	 

(** Create a false constraint *)
let false_constraint () =	
	ppl_new_NNC_Polyhedron_from_space_dimension !total_dim Empty

(** Create a true constraint *)
let true_constraint () = 
	ppl_new_NNC_Polyhedron_from_space_dimension !total_dim Universe

(** Create a linear constraint from a list of linear inequalities *)
let make inequalities = 
	let poly = true_constraint () in
	ppl_Polyhedron_add_constraints poly inequalities;
	assert_dimensions poly;
  poly
	
(** Create a linear constraint x = y & ... for a list of variable pairs (x, y) *) 
let make_equalities variable_pairs =
	let equalities = List.map (fun (x, y) -> 
		Equal (Variable x, Variable y)
	) variable_pairs in
	make equalities
	
(** Create a linear constraint x = c & ... for list of variables and constants *)
let make_set_variables value_pairs =
	let equalities = List.map (fun (v, c) -> 
		let p, q = split_q c in
		if q =! Gmp.Z.one then
			Equal (Variable v, Coefficient p)
		else
			Equal (Times (q, Variable v), Coefficient p)
	) value_pairs in
	make equalities
	
(** Create a linear constraint x = c & y = c ... for list of variables and a constant *)	
let make_set_all_variables variables c =
	let p, q = split_q c in
	let build_equality =
		if q =! Gmp.Z.one then
			fun v -> Equal (Variable v, Coefficient p)
		else
			fun v -> Equal (Times (q, Variable v), Coefficient p)
		in	
	let equalities = List.map build_equality variables in
	make equalities

(** Creates a linear constraint x in [min, max] *)
let make_interval (v, min, max) = 
	let lower_bound = 
		let p,q = split_q min in Greater_Or_Equal (Times (q, Variable v), Coefficient p) in
	let upper_bound = 
		let p,q = split_q max in Less_Or_Equal (Times (q, Variable v), Coefficient p) in
	make [lower_bound; upper_bound]
	
(** Creates linear constraints x_i in [min_i, max_i] *)
let make_box bounds =
	let lower_bounds = List.map (fun (v, min, _) ->
		let p,q = split_q min in Greater_Or_Equal (Times (q, Variable v), Coefficient p)) bounds in
	let upper_bounds = List.map (fun (v, _, max) ->
		let p,q = split_q max in Less_Or_Equal (Times (q, Variable v), Coefficient p)) bounds in
	make (lower_bounds @ upper_bounds)

	
(** Set the constraint manager *)
let set_manager int_d real_d =
	int_dim := int_d;
	real_dim := real_d;
	total_dim := int_d + real_d 

	
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Tests} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Check if a constraint is false *)
let is_false = ppl_Polyhedron_is_empty

(** Check if a constraint is true *)
let is_true = ppl_Polyhedron_is_universe

(** Check if a constraint is satisfiable *)
let is_satisfiable = fun c -> not (is_false c)

(** Check if 2 constraints are equal *)
let is_equal = ppl_Polyhedron_equals_Polyhedron

(** Check if a constraint is included in another one *)
let is_leq x y  = ppl_Polyhedron_contains_Polyhedron y x

(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Pi0-compatibility} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** Check if a linear constraint is pi0-compatible *)
let is_pi0_compatible pi0 linear_constraint =
	(* Get a list of linear inequalities *)
	let list_of_inequalities = ppl_Polyhedron_get_constraints linear_constraint in
	(* Check the pi0-compatibility for all *)
	List.for_all (is_pi0_compatible_inequality pi0) list_of_inequalities


(** Compute the pi0-compatible and pi0-incompatible inequalities within a constraint *)
let partition_pi0_compatible pi0 linear_constraint =
	(* Get a list of linear inequalities *)
	let list_of_inequalities = ppl_Polyhedron_get_constraints linear_constraint in
	(* Partition *)
	List.partition (is_pi0_compatible_inequality pi0) list_of_inequalities


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Conversion} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

(** convert to PPL polyhedron *)
let to_ppl_polyhedron x = x

(** construct from PPL polyhedron *)
let from_ppl_polyhedron x = x

(** convert to PPL constraints *)
let to_ppl_constraints x = ppl_Polyhedron_get_constraints x

(** construct from PPL constraints *)
let from_ppl_constraints constraints =
	let poly = true_constraint () in
	ppl_Polyhedron_add_constraints poly constraints;
	poly
		
(** String for the false constraint *)
let string_of_false = "false"


(** String for the true constraint *)
let string_of_true = "true"


(** Convert a linear constraint into a string *)
let string_of_linear_constraint names linear_constraint =
	(* First check if true *)
	if is_true linear_constraint then string_of_true
	(* Then check if false *)
	else if is_false linear_constraint then string_of_false
	else
	(* Get an array of linear inequalities *)
	let list_of_inequalities = ppl_Polyhedron_get_constraints linear_constraint in
	let array_of_inequalities = Array.of_list list_of_inequalities in
	"  " ^
	(string_of_array_of_string_with_sep
		"\n& "
		(Array.map (string_of_linear_inequality names) array_of_inequalities)
	)


(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)
(** {3 Functions} *)
(*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**)

let rec term_support term =
	match term with
		| Coefficient _ -> VariableSet.empty
		| Variable v -> VariableSet.add v VariableSet.empty
		| Unary_Plus t -> term_support t
		| Unary_Minus t -> term_support t
		| Plus  (lterm, rterm) -> VariableSet.union (term_support lterm) (term_support rterm)
		| Minus (lterm, rterm) -> VariableSet.union (term_support lterm) (term_support rterm)
		| Times (z, rterm) -> term_support rterm


let inequality_support ineq =
	let lterm, rterm, _ = split_linear_inequality ineq in
	VariableSet.union (term_support lterm) (term_support rterm)


(** returns a list of variables occuring in a linear constraint *)
let support linear_constraint = 
	let constr_list = ppl_Polyhedron_get_constraints linear_constraint in
	List.fold_left (fun varset constr -> 
		VariableSet.union varset (inequality_support constr)
	) VariableSet.empty constr_list
	

(** returns the lower and upper bounds of a variable wrt. a constraint *)
let bounds constr v =
	let min_bound = ( 
		let _, p, q, bounded = ppl_Polyhedron_minimize constr (Variable v) in
		if bounded then
			Some (NumConst.numconst_of_zfrac p q)
		else
			None
	) in
	let max_bound = ( 
		let _, p, q, bounded = ppl_Polyhedron_maximize constr (Variable v) in
		if bounded then
			Some (NumConst.numconst_of_zfrac p q)
		else
			None
	) in
	(min_bound, max_bound)
	

(** convex hull *)
let hull constraints =
	match constraints with
		| [] -> false_constraint ()
		| c :: tail -> 
			let hull = ppl_new_NNC_Polyhedron_from_NNC_Polyhedron c in
			List.iter (ppl_Polyhedron_poly_hull_assign hull) tail;
			hull
			

(** Performs the intersection of a list of linear constraints *)
let intersection linear_constraints =
	let result_poly = true_constraint () in
	List.iter (fun poly -> ppl_Polyhedron_intersection_assign result_poly poly) linear_constraints;
	assert_dimensions result_poly;
	result_poly	

(** Performs the intersection of a list of linear constraints *)
let intersection_assign constr linear_constraints =
	List.iter (fun poly -> ppl_Polyhedron_intersection_assign constr poly) linear_constraints;
	assert_dimensions constr


(** Let time elapse according to a domain of derivatives *)
let time_elapse linear_constraint deriv_domain =
	let poly = ppl_new_NNC_Polyhedron_from_NNC_Polyhedron linear_constraint in
	ppl_Polyhedron_time_elapse_assign poly deriv_domain;
	assert_dimensions poly;
	poly

(** Same function with sideeffects *)
let time_elapse_assign linear_constraint deriv_domain =
	ppl_Polyhedron_time_elapse_assign linear_constraint deriv_domain;
	assert_dimensions linear_constraint
	

(** Eliminate (using existential quantification) a set of variables in a linear constraint *)
let hide variables linear_constraint =
	(* copy polyhedron, as PPL function has sideeffects *)
	let poly = ppl_new_NNC_Polyhedron_from_NNC_Polyhedron linear_constraint in
	ppl_Polyhedron_unconstrain_space_dimensions poly variables;
	assert_dimensions poly;
	poly
	
(** Eliminate (using existential quantification) a set of variables in a linear constraint *)
let hide_assign variables linear_constraint =
	ppl_Polyhedron_unconstrain_space_dimensions linear_constraint variables;
	assert_dimensions linear_constraint
		

(** rename variables in a constraint *)
let rename_variables list_of_couples linear_constraint =
	(* copy polyhedron, as ppl function has sideeffects *)
	let poly = ppl_new_NNC_Polyhedron_from_NNC_Polyhedron linear_constraint in
	(* add reverse mapping *)
	let reverse_couples = List.map (fun (a,b) -> (b,a)) list_of_couples in
	let joined_couples = List.rev_append list_of_couples reverse_couples in
	(* find all dimensions that will be mapped *)
	let from, _  = List.split joined_couples in
	(* add identity pairs (x,x) for remaining dimensions *) 
	let rec add_id list i = 
		if i < 0 then list else
			if not (List.mem i from) then
				(i,i) :: add_id list (i-1)
			else
				add_id list (i-1)
		in 
	let complete_list = add_id joined_couples (!total_dim - 1) in
  (* perfom the mapping *)
	ppl_Polyhedron_map_space_dimensions poly complete_list;
	assert_dimensions poly;
	poly

				
(** rename variables in a constraint *)
let rename_variables_assign list_of_couples linear_constraint =
	(* add reverse mapping *)
	let reverse_couples = List.map (fun (a,b) -> (b,a)) list_of_couples in
	let joined_couples = List.rev_append list_of_couples reverse_couples in
	(* find all dimensions that will be mapped *)
	let from, _  = List.split joined_couples in
	(* add identity pairs (x,x) for remaining dimensions *) 
	let rec add_id list i = 
		if i < 0 then list else
			if not (List.mem i from) then
				(i,i) :: add_id list (i-1)
			else
				add_id list (i-1)
		in 
	let complete_list = add_id joined_couples (!total_dim - 1) in
  (* perfom the mapping *)
	ppl_Polyhedron_map_space_dimensions linear_constraint complete_list;
	assert_dimensions linear_constraint
												
				
(** substitutes all variables in a linear term.
		The substitution is given as a function sub: var -> linear_term *)
let rec substitute_variables_in_term sub linear_term =
	match linear_term with		
		| Coefficient z -> Coefficient z
		| Variable v -> sub v
		| Unary_Plus t -> Unary_Plus t
		| Unary_Minus t -> Unary_Minus t
		| Plus (lterm, rterm) -> (
				Plus (substitute_variables_in_term sub lterm,
							substitute_variables_in_term sub rterm))
		| Minus (lterm, rterm) -> (
				Minus (substitute_variables_in_term sub lterm,
							 substitute_variables_in_term sub rterm))
		| Times (z, rterm) -> (
				Times (z, substitute_variables_in_term sub rterm))

		
(** substitutes all variables in a linear inequality *)
let substitute_variables sub linear_inequality =
	let lterm, rterm, op = split_linear_inequality linear_inequality in
	let lsub = substitute_variables_in_term sub lterm in
	let rsub = substitute_variables_in_term sub rterm in
	build_linear_inequality lsub rsub op
	
	
(** substitutes all variables in a linear constraint *)			
let substitute sub linear_constraint =
	let inequalities = ppl_Polyhedron_get_constraints linear_constraint in
	let new_inequalities =
		List.map (substitute_variables sub) inequalities in
	let poly = true_constraint () in
	ppl_Polyhedron_add_constraints poly new_inequalities;
	assert_dimensions poly;
	poly
	
	
(** Project on list of variables *)
let project_to variables linear_constraint =
	(* Find variables to remove *)
	let to_remove = ref [] in
	for i = 0 to nb_dimensions () - 1 do
		if not (List.mem i variables) then
			to_remove := i :: !to_remove
	done;		
	ppl_Polyhedron_remove_space_dimensions linear_constraint !to_remove


(** make constraint non-strict *)
let non_strictify linear_constraint =
	let constraint_list = ppl_Polyhedron_get_constraints linear_constraint in 
	let new_constraints = List.map (fun ineq -> 
		let lterm, rterm, op = split_linear_inequality ineq in
		let newop = match op with
			| Less_Than_RS -> Less_Or_Equal_RS
			| Greater_Than_RS -> Greater_Or_Equal_RS
			| _ -> op in
		build_linear_inequality lterm rterm newop
	) constraint_list in
	make new_constraints


(** compute bounding box wrt. to a list of variables *)
let bounding_box variables constr = 
	let bounds = List.map (fun v -> (v, bounds constr v)) variables in
	let cylinder = hide variables constr in
	let boxify (v, (lbound, ubound)) =
		 match lbound with
			| Some min -> (
					let lower_bound = 
						let p,q = split_q min in Greater_Or_Equal (Times (q, Variable v), Coefficient p) in
					intersection_assign cylinder [make [lower_bound]]
				)
			| None -> ();
		 match ubound with
			| Some max -> (
					let upper_bound = 
						let p,q = split_q max in Less_Or_Equal (Times (q, Variable v), Coefficient p) in
					intersection_assign cylinder [make [upper_bound]]
				)
			| None -> () in
	List.iter boxify bounds;
	cylinder


let get_coefficients_term varlist term =
	let zero_vec = fun x -> NumConst.zero in
	let unit_vec v = fun x -> if v = x then NumConst.one else NumConst.zero in
	let ccoef = evaluate_linear_term_ppl zero_vec term in
	let vcoef = List.map (fun v -> 
		let x = evaluate_linear_term_ppl (unit_vec v) term in
		NumConst.sub x ccoef
	) varlist in
	(vcoef, ccoef) 


let get_coefficients varlist ineq = 
	let lterm, rterm, _ = split_linear_inequality ineq in
	let lvcoef, lccoef = get_coefficients_term varlist lterm in
	let rvcoef, rccoef = get_coefficients_term varlist rterm in
	let vcoef = List.map2 (fun lc rc -> 
		NumConst.sub rc lc	
	) lvcoef rvcoef in
	let ccoef = NumConst.sub rccoef lccoef in
	(vcoef, ccoef)	
			
			
let linear_system y_domain x_domain constr =
	(* size of matrix *)
	let n = List.length y_domain in
	if n <> (List.length x_domain) then raise (InternalError "size of domains differ");
	(* build index maps for variable domains *)
	let y_table = Hashtbl.create n in	
	let i = ref 0 in
	List.iter (fun vy -> 
		Hashtbl.add y_table vy !i;
		i := !i + 1
	) y_domain;
	let y_index = Hashtbl.find y_table in
	(* build linear system *)
	let a = Array.make_matrix n n NumConst.zero in
	let b = Array.make n NumConst.zero in
	(* function to find the defined variable *)
	let get_nonzero_coefs coefs =
		List.filter (fun (_, c) -> 
			NumConst.neq c NumConst.zero
		) (List.combine y_domain coefs) in
	let simple_varnames = fun x -> "x" ^ (string_of_int x) in
	(* get inequalities *)
	let eqs = ppl_Polyhedron_get_constraints constr in
	(* remove inequalities that do not refer to the selected domains *)
	let eqs = List.filter (fun eq -> 
		let sup = inequality_support eq in
		VariableSet.exists (fun v -> List.mem v (List.rev_append x_domain y_domain)) sup		
	) eqs in
	List.iter (fun eq -> 
		print_message Debug_standard (string_of_linear_inequality simple_varnames eq);
		let x_coef, c = get_coefficients x_domain eq in
		let y_coef, _ = get_coefficients y_domain eq in
		(* get defined y variable *)
		let nz = get_nonzero_coefs y_coef in
		(* no transformations supported yet *)
		if (List.length nz) <> 1 then raise (InternalError "malformed flow");
		let y, yc = List.hd nz in
		let yd = NumConst.neg yc in
		(* store coefficients in matrix *)
		let yi = y_index y in		
		let i = ref 0 in
		List.iter (fun xc -> 
			a.(yi).(!i) <- NumConst.div xc yd;
			i := !i + 1
		) x_coef;
		(* store constant coefficient in vector *)
		b.(yi) <- NumConst.div c yd				
	) eqs;
	(* print debug *)
	for i = 0 to n-1 do
		let row = Array.fold_left (fun s c -> 
			s ^ "\t" ^ (NumConst.string_of_numconst c)
		) "" a.(i) in 
		print_message Debug_standard (row ^ "\t| " ^ (NumConst.string_of_numconst b.(i)));
	done;	
	(* return matrix and vector *)
	(a, b)


(** computes an uncovered point, if it exists *)
let uncovered_point variables v0 zones =
	(* convert to powersets *)
	let universe = Ppl.ppl_new_Pointset_Powerset_NNC_Polyhedron_from_NNC_Polyhedron v0 in
	let covered = Ppl.ppl_new_Pointset_Powerset_NNC_Polyhedron_from_NNC_Polyhedron (false_constraint ()) in
	List.iter (Ppl.ppl_Pointset_Powerset_NNC_Polyhedron_add_disjunct covered) zones;
	(* compute difference *)
	let uncovered = universe in
	Ppl.ppl_Pointset_Powerset_NNC_Polyhedron_difference_assign uncovered covered;
	(* compute the sum expression of the involved variables *)
	let sum = List.fold_left (fun sum v ->
		Plus (sum, Variable v)
	) (Coefficient Gmp.Z.zero) variables in
	(* get feasible point *)
	let feasible, _, _, _, generator = ppl_Pointset_Powerset_NNC_Polyhedron_maximize_with_point uncovered sum in
	if not feasible then 
		None
	else
		match generator with
			| Point (term, q) -> (
				let coefs, _ = get_coefficients_term variables term in
				let coefs = List.map (fun c ->
					NumConst.div c (NumConst.numconst_of_mpz q) 					
				) coefs in
				Some coefs
			) 
			| _ -> None 
	