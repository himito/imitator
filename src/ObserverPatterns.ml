(*****************************************************************
 *
 *                       IMITATOR
 * 
 * File containing the operations linked to the observer patterns
 *
 * Laboratoire Specification et Verification (ENS Cachan & CNRS, France)
 * Universite Paris 13, Sorbonne Paris Cite, LIPN (France)
 * 
 * Author:        Etienne Andre
 * 
 * Created:       2013/02/04
 * Last modified: 2013/03/06
 *
 ****************************************************************)


(****************************************************************)
(** Modules *)
(****************************************************************)
open Global
open AbstractModel
open LinearConstraint


(****************************************************************)
(** Constants *)
(****************************************************************)
let automaton_name = "observer"
let clock_name = "x_obs"
let location_prefix = "locobs_"


let location_name location_index =
	location_prefix ^ (string_of_int location_index)

(** Shortcuts *)
let truec = LinearConstraint.true_constraint


(****************************************************************)
(** Useful (parameterized) constants *)
(****************************************************************)
let untimedt destination_index = [truec (), No_update, [], destination_index]

(* Constraint x <= d, with d linear_term : d - x >= 0 *)
let ct_x_leq_d x d =
	(* Build the linear term *)
	let lt = add_linear_terms d (LinearConstraint.make_linear_term [NumConst.minus_one, x] NumConst.zero) in
	(* Build constraint *)
	LinearConstraint.make [LinearConstraint.make_linear_inequality lt LinearConstraint.Op_ge]


(* Constraint x >= d, with d linear_term : x - d >= 0 *)
let ct_x_geq_d x d =
	(* Build the linear term *)
	let lt = sub_linear_terms (LinearConstraint.make_linear_term [NumConst.one, x] NumConst.zero) d in
	(* Build constraint *)
	LinearConstraint.make [LinearConstraint.make_linear_inequality lt LinearConstraint.Op_ge]


(* Linear inequality x = d, with d linear_term : d - x >= 0 *)
let lt_x_eq_d x d =
	(* Build the linear term *)
	let lt = add_linear_terms d (LinearConstraint.make_linear_term [NumConst.minus_one, x] NumConst.zero) in
	(* Build linear inequality *)
	LinearConstraint.make_linear_inequality lt LinearConstraint.Op_eq


(* Constraint x = d, with d linear_term : d - x >= 0 *)
let ct_x_eq_d x d =
	(* Build constraint *)
	LinearConstraint.make [lt_x_eq_d x d]


(* Linear constraint x = 0 *)
let lc_x_eq_0 x =
	(* Build the linear term *)
	let lt = (LinearConstraint.make_linear_term [NumConst.minus_one, x] NumConst.zero) in
	(* Build linear constraint *)
	LinearConstraint.make [LinearConstraint.make_linear_inequality lt LinearConstraint.Op_eq]



(****************************************************************)
(** Functions *)
(****************************************************************)

(* Create the new automata and new clocks necessary for the observer *)
let new_elements = function
	| None -> (None , None)
	| Some property ->
	begin
		match property with
		(* Not a real observer: does not build anything *)
		| ParsingStructure.Unreachable_location _ -> (None , None)
		
		(* Untimed observers: add automaton, does not add clock *)
		| ParsingStructure.Action_precedence_acyclic _
		| ParsingStructure.Action_precedence_cyclic _
		| ParsingStructure.Action_precedence_cyclicstrict _
		| ParsingStructure.Eventual_response_acyclic _
		| ParsingStructure.Eventual_response_cyclic _
		| ParsingStructure.Eventual_response_cyclicstrict _
		| ParsingStructure.Sequence_acyclic _
		| ParsingStructure.Sequence_cyclic _
			-> (Some automaton_name, None)
		
		(* Timed observers: add automaton, add clock *)
		| ParsingStructure.Action_deadline _
		| ParsingStructure.TB_Action_precedence_acyclic _
		| ParsingStructure.TB_Action_precedence_cyclic _
		| ParsingStructure.TB_Action_precedence_cyclicstrict _
		| ParsingStructure.TB_response_acyclic _
		| ParsingStructure.TB_response_cyclic _
		| ParsingStructure.TB_response_cyclicstrict _
			-> (Some automaton_name, Some clock_name)
	
	end

(* Get the number of locations for this observer *)
let get_nb_locations = function
	| None -> 0
	| Some property ->
	begin
		match property with
		(* Not a real observer: does not build anything *)
		| ParsingStructure.Unreachable_location _ -> 0
		
		| ParsingStructure.Action_precedence_acyclic _
		| ParsingStructure.Action_precedence_cyclic _
		| ParsingStructure.Action_precedence_cyclicstrict _
			-> 3
		| ParsingStructure.Eventual_response_acyclic _ -> 3
		| ParsingStructure.Eventual_response_cyclic _ -> 2
		| ParsingStructure.Eventual_response_cyclicstrict _ -> 3
		| ParsingStructure.Action_deadline _ -> 3
		| ParsingStructure.TB_Action_precedence_acyclic _ -> 4
		| ParsingStructure.TB_Action_precedence_cyclic _ -> 3
		| ParsingStructure.TB_Action_precedence_cyclicstrict _ -> 3
		| ParsingStructure.TB_response_acyclic _ -> 4
		| ParsingStructure.TB_response_cyclic _ -> 3
		| ParsingStructure.TB_response_cyclicstrict _ -> 3
		| ParsingStructure.Sequence_acyclic list_of_actions -> (List.length list_of_actions) + 2
		| ParsingStructure.Sequence_cyclic list_of_actions -> (List.length list_of_actions) + 1
	end


(* Create the list of location indexes for this observer *)
let get_locations property =
	let nb = get_nb_locations property in
	Array.of_list(
		List.map location_name(
			if nb = 0 then [] else
				list_of_interval 0 (nb-1)
		)
	)

(*------------------------------------------------------------*)
(* Create the observer; 
	Takes as parameters the number of actions, the automaton_index, the nosync index for the observer, the local clock id for the observer
	Returns:
	- Actions per automaton
	- Actions per location
	- Transitions
	- Invariants
*)
(*------------------------------------------------------------*)
let get_automaton nb_actions automaton_index nosync_index x_obs property = 
	(* Create the common structures *)
	let initialize_structures nb_locations all_actions =
		(*Array for actions for location *)
		let actions_per_location = 	Array.make nb_locations [] in
		(* All observers are complete: fill *)
		for i = 0 to nb_locations-1 do
			actions_per_location.(i) <- all_actions;
		done;
		(* Return : *)
		actions_per_location,
		(* Array for invariants *)
		Array.make nb_locations (truec ()),
		(* Array for transitions *)
		(let transitions = Array.make nb_locations (Array.make nb_actions []) in
			(* Initialize transitions ! Otherwise pointers problems *)
			for location_index = 0 to nb_locations - 1 do
				transitions.(location_index) <- Array.make nb_actions [];
			done;
		transitions
		)
		,
		(* The array of transitions for locations who allow all declared observer actions for a location, as self-loops *)
		function location_index ->
			let allow_all = Array.make nb_actions [] in
			List.iter (fun action_index -> allow_all.(action_index) <- untimedt location_index) all_actions;
			allow_all
	in
	
	match property with
	| Noproperty -> raise (InternalError("The function 'get_automaton' should not be called in case of no observer."))
	(* Not a real observer: does not build anything *)
	| Unreachable_location _ -> raise (InternalError("The function 'get_automaton' should not be called in case of a degenerate observer."))
	
	
	| Action_precedence_acyclic (a1, a2) -> 
		let nb_locations = 3 in
		let all_actions = [a1;a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* No need to update actions per location (no nosync action here) *)
		
		(* Compute transitions *)
		transitions.(0).(a1) <- untimedt 1;
		transitions.(0).(a2) <- untimedt 2;
		transitions.(1) <- allow_all 1;
		transitions.(2) <- allow_all 2;
		(* Return structure *)
		all_actions, actions_per_location, invariants, transitions,
		(* No init inequality *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
	
	
	| Action_precedence_cyclic (a1, a2) -> 
		let nb_locations = 3 in
		let all_actions = [a1;a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* No need to update actions per location (no nosync action here) *)

		(* Compute transitions *)
		transitions.(0).(a1) <- untimedt 1;
		transitions.(0).(a2) <- untimedt 2;
		transitions.(1).(a1) <- untimedt 1;
		transitions.(1).(a2) <- untimedt 0;
		transitions.(2) <- allow_all 2;
		(*print_message Debug_standard ("Index of a1: " ^ (string_of_int a1) ^ " ; index of a2: " ^ (string_of_int a2) ^ "");
		for location_index = 0 to nb_locations - 1 do
			for action_index = 0 to nb_actions - 1 do
				let t = transitions.(location_index).(action_index) in
				match t with
				| [] -> print_message Debug_standard ("Location " ^ (string_of_int location_index) ^ "  -> action " ^ (string_of_int action_index) ^ " : nothing")
				| [(_, _, _, destination_index)] -> print_message Debug_standard ("Location " ^ (string_of_int location_index) ^ "  -> action " ^ (string_of_int action_index) ^ " : " ^ (string_of_int destination_index) ^ "")
				| _ -> print_message Debug_standard ("Location " ^ (string_of_int location_index) ^ "  -> action " ^ (string_of_int action_index) ^ " : something else")
			done;
		done;*)
		(* Return structure *)
		all_actions, actions_per_location, invariants, transitions,
		(* No init inequality *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
	
	
	| Action_precedence_cyclicstrict (a1, a2) -> 
		let nb_locations = 3 in
		let all_actions = [a1;a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* No need to update actions per location (no nosync action here) *)
		
		(* Compute transitions *)
		transitions.(0).(a1) <- untimedt 1;
		transitions.(0).(a2) <- untimedt 2;
		transitions.(1).(a1) <- untimedt 2;
		transitions.(1).(a2) <- untimedt 0;
		transitions.(2) <- allow_all 2;
		(* Return structure *)
		all_actions, actions_per_location, invariants, transitions,
		(* No init inequality *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
		
	
	| Eventual_response_acyclic (a1, a2)
	| Eventual_response_cyclic (a1, a2)
	| Eventual_response_cyclicstrict (a1, a2)
		-> raise (InternalError("???"))
	
	
	| Action_deadline (a, d) -> 
		let nb_locations = 3 in
		let all_actions = [a] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* Update actions per location for the silent action *)
		actions_per_location.(0) <- nosync_index :: all_actions;
		(* Update invariants *)
		invariants.(0) <- ct_x_leq_d x_obs d;
		(* Compute transitions *)
		transitions.(0).(a) <- untimedt 1;
		transitions.(0).(nosync_index) <- [ct_x_eq_d x_obs d, No_update, [], 2];
		transitions.(1) <- allow_all 1;
		transitions.(2) <- allow_all 2;
		(* Return structure (and add silent action) *)
		nosync_index :: all_actions, actions_per_location, invariants, transitions,
		(* Return x_obs = 0 *)
		Some (lc_x_eq_0 x_obs),
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
		
	
	| TB_Action_precedence_acyclic (a1, a2, d) -> 
		let nb_locations = 4 in
		let all_actions = [a1; a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* No need to update actions per location (no silent action here) *)
		(* Compute transitions *)
		transitions.(0).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(0).(a2) <- untimedt 3;
		transitions.(1).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(1).(a2) <- [
			ct_x_leq_d x_obs d, No_update, [], 2;
			ct_x_geq_d x_obs d, No_update, [], 3
			];
		transitions.(2) <- allow_all 2;
		transitions.(3) <- allow_all 3;
		(* Return structure *)
		all_actions, actions_per_location, invariants, transitions,
		(* No init constraint *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 3)
	
	
	| TB_Action_precedence_cyclic (a1, a2, d) -> 
		let nb_locations = 3 in
		let all_actions = [a1; a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* No need to update actions per location (no silent action here) *)
		(* Compute transitions *)
		transitions.(0).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(0).(a2) <- untimedt 2;
		transitions.(1).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(1).(a2) <- [
			ct_x_leq_d x_obs d, No_update, [], 0;
			ct_x_geq_d x_obs d, No_update, [], 2
			];
		transitions.(2) <- allow_all 2;
		(* Return structure *)
		all_actions, actions_per_location, invariants, transitions,
		(* No init constraint *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
		
		
	| TB_Action_precedence_cyclicstrict (a1, a2, d) -> 
		let nb_locations = 3 in
		let all_actions = [a1; a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* No need to update actions per location (no silent action here) *)
		(* Compute transitions *)
		transitions.(0).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(0).(a2) <- untimedt 2;
		transitions.(1).(a1) <- untimedt 2;
		transitions.(1).(a2) <- [
			ct_x_leq_d x_obs d, No_update, [], 0;
			ct_x_geq_d x_obs d, No_update, [], 2
			];
		transitions.(2) <- allow_all 2;
		(* Return structure *)
		all_actions, actions_per_location, invariants, transitions,
		(* No init constraint *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
		

	| TB_response_acyclic (a1, a2, d) -> 
		let nb_locations = 4 in
		let all_actions = [a1; a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* Update actions per location for the silent action *)
		actions_per_location.(1) <- nosync_index :: all_actions;
		(* Update invariants *)
		invariants.(1) <- ct_x_leq_d x_obs d;
		(* Compute transitions *)
		transitions.(0).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(0).(a2) <- untimedt 0;
		transitions.(1).(a1) <- untimedt 1;
		transitions.(1).(a2) <- untimedt 2;
		transitions.(1).(nosync_index) <- [ct_x_eq_d x_obs d, No_update, [], 3];
		transitions.(2) <- allow_all 2;
		transitions.(3) <- allow_all 3;
		(* Return structure (and add silent action) *)
		nosync_index :: all_actions, actions_per_location, invariants, transitions,
		(* No init constraint *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 3)
		
	| TB_response_cyclic (a1, a2, d) -> 
		let nb_locations = 3 in
		let all_actions = [a1; a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* Update actions per location for the silent action *)
		actions_per_location.(1) <- nosync_index :: all_actions;
		(* Update invariants *)
		invariants.(1) <- ct_x_leq_d x_obs d;
		(* Compute transitions *)
		transitions.(0).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(0).(a2) <- untimedt 0;
		transitions.(1).(a1) <- untimedt 1;
		transitions.(1).(a2) <- untimedt 0;
		transitions.(1).(nosync_index) <- [ct_x_eq_d x_obs d, No_update, [], 2];
		transitions.(2) <- allow_all 2;
		(* Return structure (and add silent action) *)
		nosync_index :: all_actions, actions_per_location, invariants, transitions,
		(* No init constraint *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
	
	
	| TB_response_cyclicstrict (a1, a2, d) -> 
		let nb_locations = 3 in
		let all_actions = [a1; a2] in
		(* Initialize *)
		let actions_per_location, invariants, transitions, allow_all = initialize_structures nb_locations all_actions in
		(* Update actions per location for the silent action *)
		actions_per_location.(1) <- nosync_index :: all_actions;
		(* Update invariants *)
		invariants.(1) <- ct_x_leq_d x_obs d;
		(* Compute transitions *)
		transitions.(0).(a1) <- [truec (), Resets [x_obs], [], 1];
		transitions.(0).(a2) <- untimedt 2;
		transitions.(1).(a1) <- untimedt 2;
		transitions.(1).(a2) <- untimedt 0;
		transitions.(1).(nosync_index) <- [ct_x_eq_d x_obs d, No_update, [], 2];
		transitions.(2) <- allow_all 2;
		(* Return structure (and add silent action) *)
		nosync_index :: all_actions, actions_per_location, invariants, transitions,
		(* No init constraint *)
		None,
		(* Reduce to reachability property *)
		Unreachable (automaton_index, 2)
						(*	
	|TB_response_acyclic _ -> 4
	| TB_response_cyclic _ -> 3
	| TB_response_cyclicstrict _ -> 3
	| Sequence_acyclic list_of_actions -> (List.length list_of_actions) + 2
	| Sequence_cyclic list_of_actions -> (List.length list_of_actions) + 1*)
	| _ -> raise (InternalError("Not implemented"))

