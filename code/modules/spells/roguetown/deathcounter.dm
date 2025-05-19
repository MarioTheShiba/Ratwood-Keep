/obj/effect/proc_holder/spell/invoked/deathcounter
	name = "Death Counter"
	desc = "Death."
	range = 0
	miracle = FALSE
	movement_interrupt = FALSE
	sound = 'sound/magic/deathcounter.ogg'
	antimagic_allowed = TRUE
	var/counter_active = FALSE
	var/duration = 50


/obj/effect/proc_holder/spell/invoked/deathcounter/cast(list/targets, mob/living/user)
	if (!isliving(user))
		return FALSE

	var/mob/living/M = user

	if (M.anti_magic_check(TRUE, TRUE))
		return FALSE

	if (counter_active)
		M.show_message(span_warning("Already performing a death counter."))
		return FALSE

	M.visible_message(
		span_warning("[M] feels incredibly menacing...You should probably not attack them."),
		span_notice("You prepare to send someone to Necra.")
		)

	counter_active = TRUE


	M.AddElement(/datum/element/relay_attackers)
	RegisterSignal(M, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))

	addtimer(CALLBACK(src, PROC_REF(disable_deathcounter), M), duration)
	return TRUE

/obj/effect/proc_holder/spell/invoked/deathcounter/proc/on_attacked(mob/victim, mob/living/attacker)
	SIGNAL_HANDLER
	if (!isliving(attacker))
		return
	attacker.Immobilize(3 SECONDS)
	addtimer(CALLBACK(attacker, TYPE_PROC_REF(/mob/living, Knockdown), 3 SECONDS), 1 SECONDS)


/obj/effect/proc_holder/spell/invoked/deathcounter/proc/disable_deathcounter(mob/user)
	user.RemoveElement(/datum/element/relay_attackers)
	UnregisterSignal(user, COMSIG_ATOM_WAS_ATTACKED)
	counter_active = FALSE
