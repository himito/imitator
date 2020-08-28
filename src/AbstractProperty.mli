(************************************************************
 *
 *                       IMITATOR
 *
 * Université de Lorraine, CNRS, Inria, LORIA, Nancy, France
 *
 * Module description: Property description
 *
 * File contributors : Étienne André
 * Created           : 2019/10/08
 * Last modified     : 2020/08/25
 *
 ************************************************************)



(************************************************************)
(* Modules *)
(************************************************************)
open Automaton
(* open AbstractModel *)


(****************************************************************)
(** Predicates for properties *)
(****************************************************************)

type loc_predicate =
	| Loc_predicate_EQ of automaton_index * location_index
	| Loc_predicate_NEQ of automaton_index * location_index


type simple_predicate =
	| Discrete_boolean_expression of DiscreteExpressions.discrete_boolean_expression
	| Loc_predicate of loc_predicate


type state_predicate_factor =
	| State_predicate_factor_NOT of state_predicate_factor
	| Simple_predicate of simple_predicate
	| State_predicate of state_predicate

and state_predicate_term =
	| State_predicate_term_AND of state_predicate_term * state_predicate_term
	| State_predicate_factor of state_predicate_factor

and state_predicate =
	| State_predicate_OR of state_predicate * state_predicate
	| State_predicate_term of state_predicate_term
	(*** NOTE: added for conveniency, notably to create 'dummy' predicates ***)
	| State_predicate_true
	| State_predicate_false


(************************************************************)
(** Definition of property *)
(************************************************************)

type duration = LinearConstraint.p_linear_term

type property =

	(*------------------------------------------------------------*)
	(* Non-nested CTL *)
	(*------------------------------------------------------------*)

	(* Reachability *)
	| EF of state_predicate
	
	(* Safety *)
	| AGnot of state_predicate
	
	
(*	
	(* Unavoidability *)
	| AF of state_predicate
*)
	
	(*------------------------------------------------------------*)
	(* Reachability and specification illustration *)
	(*------------------------------------------------------------*)
	
	(** EF-synthesis with examples of (un)safe words *)
	| EFexemplify of state_predicate
	
	(*------------------------------------------------------------*)
	(* Optimized reachability *)
	(*------------------------------------------------------------*)
	
	(* Reachability with minimization of a parameter valuation *)
	| EFpmin of state_predicate * parameter_index
	
	(* Reachability with maximization of a parameter valuation *)
	| EFpmax of state_predicate * parameter_index
	
	(* Reachability with minimal-time *)
	| EFtmin of state_predicate
	

	(*------------------------------------------------------------*)
	(* Cycles *)
	(*------------------------------------------------------------*)
	
	(** Infinite-run (cycle) *)
	| Cycle

	(** Accepting infinite-run (cycle) *)
	| Accepting_cycle of state_predicate

	(** Infinite-run (cycle) with non-Zeno assumption: method by checking whether the PTA is already a CUB-PTA for some valuation *)
	| NZCycle_check
	
	(** Infinite-run (cycle) with non-Zeno assumption: method by transforming the PTA into a CUB-PTA *)
	| NZCycle_transform
	
	(** Infinite-run (cycle) with non-Zeno assumption: method assuming the PTA is already a CUB-PTA *)
	| NZCycle_CUB
	

	(*------------------------------------------------------------*)
	(* Deadlock-freeness *)
	(*------------------------------------------------------------*)
	
	(* Deadlock-free synthesis *)
	| Deadlock_Freeness

	
	(*------------------------------------------------------------*)
	(* Inverse method, trace preservation, robustness *)
	(*------------------------------------------------------------*)
	
	(* Inverse method with complete, non-convex result *)
	| IM of PVal.pval

	(* Non-complete, non-deterministic inverse method with convex result *)
	| ConvexIM of PVal.pval

	(* Parametric reachability preservation *)
	| PRP of state_predicate * PVal.pval

	(* Variant IMK of the Inverse method *)
	| IMK of PVal.pval

	(* Variant IMunion of the Inverse method *)
	| IMunion of PVal.pval

	
	(*------------------------------------------------------------*)
	(* Cartography algorithms *)
	(*------------------------------------------------------------*)
	
	(* Cartography *)
	| Cover_cartography of HyperRectangle.hyper_rectangle

	(** Cover the whole cartography using learning-based abstractions *)
	| Learning_cartography of state_predicate * HyperRectangle.hyper_rectangle
	
	(** Cover the whole cartography after shuffling point (mostly useful for the distributed IMITATOR) *)
	| Shuffle_cartography of HyperRectangle.hyper_rectangle
	
	(** Look for the border using the cartography*)
	| Border_cartography of HyperRectangle.hyper_rectangle
	
	(** Randomly pick up values for a given number of iterations *)
	| Random_cartography of HyperRectangle.hyper_rectangle * int
	
	(** Randomly pick up values for a given number of iterations, then switch to sequential algorithm once no more point has been found after a given max number of attempts (mostly useful for the distributed IMITATOR) *)
	| RandomSeq_cartography of HyperRectangle.hyper_rectangle * int

	(* Parametric reachability preservation *)
	| PRPC of state_predicate * HyperRectangle.hyper_rectangle




type synthesis_type =
	(* (tentative) exhibition of at least one valuation for which a property holds *)
	| Witness
	(* (tentative) synthesis of all valuations for which a property holds *)
	| Synthesis


type projection = (parameter_index list) option

  
(************************************************************)
(** The actual property *)
(************************************************************)

type abstract_property = {
	(* Emptiness or synthesis *)
	synthesis_type	: synthesis_type;
	(* Property *)
	property		: property;
	(* Projection of the result *)
	projection		: projection;
}


