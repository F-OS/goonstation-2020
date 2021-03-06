/////////////////////////////////////////////
// Mustard Gas
/////////////////////////////////////////////


/obj/effects/mustard_gas
	name = "mustard gas"
	icon_state = "mustard"
	opacity = 1
	anchored = 0.0
	mouse_opacity = 0
	var/amount = 6.0
	event_handler_flags = USE_HASENTERED

/obj/effects/mustard_gas/New()
	..()
	SPAWN_DBG (100)
		dispose()
	return

/obj/effects/mustard_gas/Move()
	..()
	for(var/mob/living/carbon/human/R in get_turf(src))
		if (R.internal != null && R.wear_mask && (R.wear_mask.c_flags & MASKINTERNALS))
		else
			R.TakeDamage("chest", 0, 10)
			R.losebreath = max(5, R.losebreath)
			R.emote("scream")
			if (prob(25))
				R.changeStatus("stunned", 1 SECONDS)
			R.updatehealth()
	return

/obj/effects/mustard_gas/HasEntered(mob/living/carbon/human/R as mob )
	..()
	if (ishuman(R))
		if (R.internal != null && R.wear_mask && (R.wear_mask.c_flags & MASKINTERNALS))
			return
		R.losebreath = max(5, R.losebreath)
		R.TakeDamage("chest", 0, 10)
		R.emote("scream")
		if (prob(25))
			R.changeStatus("stunned", 1 SECONDS)
		R.updatehealth()
	return

/obj/effects/medusa_gas
	name = "medusa gas"
	icon_state = "medusa"
	opacity = 1
	anchored = 0.0
	mouse_opacity = 0
	var/amount = 8.0
	event_handler_flags = USE_HASENTERED

/obj/effects/medusa_gas/New()
	..()
	SPAWN_DBG (100)
		dispose()
	return

/obj/effects/medusa_gas/Move()
	..()
	for(var/mob/living/carbon/human/R in get_turf(src))
		if (R.internal != null && R.wear_mask && (R.wear_mask.c_flags & MASKINTERNALS))
		else
			R.reagents.add_reagent("medusa", 2)
			R.emote("cough")
			if (prob(25))
				R.changeStatus("stunned", 1 SECONDS)
			R.updatehealth()
	return

/obj/effects/medusa_gas/HasEntered(mob/living/carbon/human/R as mob )
	..()
	if (ishuman(R))
		if (R.internal != null && R.wear_mask && (R.wear_mask.c_flags & MASKINTERNALS))
			return
		R.reagents.add_reagent("medusa", 2)
		R.emote("cough")
		if (prob(25))
			R.changeStatus("stunned", 1 SECONDS)
		R.updatehealth()
	return