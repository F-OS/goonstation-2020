/obj/machinery/computer/ordercomp
	name = "Supply Request Console"
	icon = 'icons/obj/computer.dmi'
	icon_state = "QMreq"
	var/temp = null
	var/obj/item/card/id/scan = null
	var/console_location = null

	lr = 1
	lg = 0.7
	lb = 0.03

	New()
		..()
		console_location = get_area(src)
		return

	disposing()
		radio_controller.remove_object(src, "1149")
		..()

/obj/machinery/computer/ordercomp/console_upper
	icon = 'icons/obj/computerpanel.dmi'
	icon_state = "qmreq1"
/obj/machinery/computer/ordercomp/console_lower
	icon = 'icons/obj/computerpanel.dmi'
	icon_state = "qmreq1"

/obj/machinery/computer/ordercomp/attackby(I as obj, user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/ordercomp/attack_ai(var/mob/user as mob)
	boutput(user, "<span style=\"color:red\">AI Interfacing with this computer has been disabled.</span>")
	return

/obj/machinery/computer/ordercomp/attack_hand(var/mob/user as mob)
	if(..())
		return

	if (!global.QM_CategoryList)
		message_coders("ZeWaka/QMCategories: QMcategoryList was not found!")

	user.machine = src
	var/dat
	if (src.temp)
		dat = src.temp
	else

		dat += {"<B>Shipping Budget:</B> [wagesystem.shipping_budget] Credits<BR>
		<B>Scanned Card:</B> <A href='?src=\ref[src];card=1'>([src.scan])</A><BR><HR>"}
		if(src.scan != null)
			var/datum/data/record/account = null
			account = FindBankAccountByName(src.scan.registered)
			if(account)
				dat += "<B>Credits on Account:</B> [account.fields["current_money"]] Credits<BR><HR>"
		dat += {"<A href='?src=\ref[src];viewrequests=1'>View Requests</A><BR>
		<A href='?src=\ref[src];order=1'>Request Items</A><BR>
		<A href='?src=\ref[src];buypoints=1'>Purchase Supply Points</A><BR>
		<A href='?action=mach_close&window=computer'>Close</A>"}
		//<A href='?src=\ref[src];vieworders=1'>View Approved Orders</A><BR><BR> This right here never worked anyway.
	user.Browse(dat, "title=Supply Request Console;window=computer_[src];size=575x450")
	onclose(user, "computer_[src]")
	return

/obj/machinery/computer/ordercomp/attackby(var/obj/item/I as obj, user as mob)
	if (istype(I, /obj/item/card/id) || (istype(I, /obj/item/device/pda2) && I:ID_card))
		if (istype(I, /obj/item/device/pda2) && I:ID_card) I = I:ID_card
		boutput(user, "<span style=\"color:blue\">You swipe the ID card.</span>")
		var/datum/data/record/account = null
		account = FindBankAccountByName(I:registered)
		if(account)
			var/enterpin = input(user, "Please enter your PIN number.", "Order Console", 0) as null|num
			if (enterpin == I:pin)
				boutput(user, "<span style=\"color:blue\">Card authorized.</span>")
				src.scan = I
			else
				boutput(user, "<span style=\"color:red\">Pin number incorrect.</span>")
				src.scan = null
		else
			boutput(user, "<span style=\"color:red\">No bank account associated with this ID found.</span>")
			src.scan = null
	else src.attack_hand(user)
	return

/obj/machinery/computer/ordercomp/Topic(href, href_list)
	if(..())
		return

	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (issilicon(usr)))
		usr.machine = src

	if (href_list["order"])
		var/datum/data/record/account = null
		if(src.scan) account = FindBankAccountByName(src.scan.registered)
		if(account)
			src.temp = "<B>Credits on Account:</B> [account.fields["current_money"]] Credits<BR><HR>"
		else
			src.temp = "<B>Shipping Budget:</B> [wagesystem.shipping_budget] Credits<BR><HR>"
		src.temp += "<B>Please select the Supply Package you would like to request:</B><BR><BR>"

		src.temp += {"<style>
			table {border-collapse: collapse;}
			th,td {padding: 5px;}
			.categoryGroup {padding:5px; margin-bottom:8px; border:1px solid black}
			.categoryGroup .title {display:block; color:white; padding: 2px 5px; margin: -5px -5px 2px -5px;
															width: auto;
															height: auto; /* MAXIMUM COMPATIBILITY ACHIEVED */
															filter: glow(color=black,strength=1);
															text-shadow: -1px -1px 0 #000,
																						1px -1px 0 #000,
																						-1px 1px 0 #000,
																						 1px 1px 0 #000;}
		</style>"}

		for (var/foundCategory in global.QM_CategoryList)
			var/categorycolor = random_color()

			src.temp += {"<div class='categoryGroup' id='[foundCategory]' style='border-color:[categorycolor]'>
											<b class='title' style='background:[categorycolor]'>[foundCategory]</b>"}

			src.temp += "<table border=1>"
			src.temp += "<tr><th>Item</th><th>Cost (Credits)</th><th>Contents</th></tr>"

			for (var/datum/supply_packs/S in qm_supply_cache) //yes I know what this is doing, feel free to make it more perf-friendly
				if(S.syndicate || S.hidden) continue
				if (S.category == foundCategory)
					src.temp += "<tr><td><a href='?src=\ref[src];doorder=\ref[S]'><b><u>[S.name]</u></b></a></td><td>[S.cost]</td><td>[S.desc]</td></tr>"
				LAGCHECK(LAG_LOW)

			src.temp+="</table></div>"

		src.temp += "<hr><A href='?src=\ref[src];mainmenu=1'>Main Menu</A><br>"

	else if (href_list["doorder"])
		var/datum/data/record/account = null
		if(src.scan) account = FindBankAccountByName(src.scan.registered)
		var/datum/supply_order/O = new/datum/supply_order ()
		var/datum/supply_packs/P = locate(href_list["doorder"])
		if(istype(P))
			// The order computer has no emagged / other ability to display hidden or syndicate packs.
			// It follows that someone's being clever if trying to order either of these items
			if(P.syndicate || P.hidden)
				// Get that jerk
				if (usr in range(1))
					//Check that whoever's doing this is nearby - otherwise they could gib any old scrub
					trigger_anti_cheat(usr, "tried to href exploit order packs on [src]")

				return
			if(account) //buy it with their money
				if(account.fields["current_money"] < P.cost)
					src.temp = "Insufficient funds in account. Log out to request purchase using supply budget.<BR>"
				else
					account.fields["current_money"] -= P.cost
					O.object = P
					O.orderedby = usr.name
					O.console_location = src.console_location
					process_supply_order(O,usr)
					logTheThing("station", usr, null, "ordered a [P.name] at [log_loc(src)].")
					src.temp = "Your order has been processed and will be delivered shortly.<BR>"
					supply_history += "[O.object.name] ordered by [O.orderedby] for [P.cost] credits from personal account.<BR>"

					// pda alert ////////
					var/datum/radio_frequency/transmit_connection = radio_controller.return_frequency("1149")
					var/datum/signal/pdaSignal = get_free_signal()
					pdaSignal.data = list("address_1"="00000000", "command"="text_message", "sender_name"="CARGO-MAILBOT",  "group"="cargo", "sender"="00000000", "message"="Notification: [O.object] ordered by [O.orderedby] using personal account at [O.console_location].")
					pdaSignal.transmission_method = TRANSMISSION_RADIO
					if(transmit_connection != null)
						transmit_connection.post_signal(src, pdaSignal)
					//////////////////
			else
				O.object = P
				O.orderedby = usr.name
				O.console_location = src.console_location
				supply_requestlist += O
				src.temp = "Request sent to Supply Console. The Quartermasters will process your request as soon as possible.<BR>"

				// pda alert ////////
				var/datum/radio_frequency/transmit_connection = radio_controller.return_frequency("1149")
				var/datum/signal/pdaSignal = get_free_signal()
				pdaSignal.data = list("address_1"="00000000", "command"="text_message", "sender_name"="CARGO-MAILBOT",  "group"="cargo", "sender"="00000000", "message"="Notification: [O.object] requested by [O.orderedby] at [O.console_location].")
				pdaSignal.transmission_method = TRANSMISSION_RADIO
				if(transmit_connection != null)
					transmit_connection.post_signal(src, pdaSignal)
				//////////////////
		else
			src.temp = "Communications error with central supply console. Please notify a Certified Service Technician.<BR>"
		src.temp += {"<BR><A href='?src=\ref[src];mainmenu=1'>Main Menu</A>
					<BR><A href='?src=\ref[src];order=1'>Back to Order List</A>"}

	else if (href_list["viewrequests"])
		src.temp = "<B>Current Requests:</B><BR><BR>"
		for(var/S in supply_requestlist)
			var/datum/supply_order/SO = S
			src.temp += "[SO.object.name] requested by [SO.orderedby] from [SO.console_location].<BR>"
		src.temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

	else if (href_list["card"])
		if (src.scan) src.scan = null
		else
			var/obj/item/I = usr.equipped()
			if (istype(I, /obj/item/magtractor))
				var/obj/item/magtractor/mag = I
				if (istype(mag.holding, /obj/item/card/id))
					I = mag.holding
			if (istype(I, /obj/item/card/id) || (istype(I, /obj/item/device/pda2) && I:ID_card))
				if (istype(I, /obj/item/device/pda2) && I:ID_card) I = I:ID_card
				boutput(usr, "<span style=\"color:blue\">You swipe the ID card.</span>")
				var/datum/data/record/account = null
				account = FindBankAccountByName(I:registered)
				if(account)
					var/enterpin = input(usr, "Please enter your PIN number.", "Order Console", 0) as null|num
					if (enterpin == I:pin)
						boutput(usr, "<span style=\"color:blue\">Card authorized.</span>")
						src.scan = I
					else
						boutput(usr, "<span style=\"color:red\">Pin number incorrect.</span>")
						src.scan = null
				else
					boutput(usr, "<span style=\"color:red\">No bank account associated with this ID found.</span>")
					src.scan = null
			else
				src.temp = "There is no card scan to log out.<BR>"
				src.temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"

	else if (href_list["buypoints"])

		if (src.scan)
			var/datum/data/record/account = null
			account = FindBankAccountByName(src.scan.registered)
			if (!account)
				src.temp = {"<B>ERROR:</B> No bank account associated with this ID card found.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
			else
				src.temp = {"<B>Contribute to Shipping Budget</B><BR>
							<B>Shipping Budget:</b> [wagesystem.shipping_budget] Credits<BR>
							<B>Credits in Account:</B> [account.fields["current_money"]] Credits<BR><HR>
							<A href='?src=\ref[src];buy=1'>Make Transaction</A><BR>
							<A href='?src=\ref[src];mainmenu=1'>Cancel Purchase</A>"}
		else
			src.temp = {"You need to swipe an ID card first!<BR>
						<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}

	else if (href_list["buy"])
		if (src.scan)
			if (src.scan.registered in FrozenAccounts)
				boutput(usr, "<span style=\"color:red\">Your account cannot currently be liquidated due to active borrows.</span>")
				return
			var/datum/data/record/account = null
			account = FindBankAccountByName(src.scan.registered)
			if (!account)
				src.temp = {"<B>ERROR:</B> No bank account associated with this ID card found.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
			var/transaction = input("How much?", "Shipping Budget", null, null)  as null|num
			if (account.fields["current_money"] >= transaction && (transaction > 0))
				account.fields["current_money"] -= transaction
				wagesystem.shipping_budget += transaction
				src.temp = "Transaction successful. Thank you for your patronage.<BR>"
				////// PDA NOTIFY/////
				var/datum/radio_frequency/transmit_connection = radio_controller.return_frequency("1149")
				var/datum/signal/pdaSignal = get_free_signal()
				pdaSignal.data = list("address_1"="00000000", "command"="text_message", "sender_name"="CARGO-MAILBOT",  "group"="cargo", "sender"="00000000", "message"="Notification: [transaction] credits transfered to shipping budget from [src.scan.registered].")
				pdaSignal.transmission_method = TRANSMISSION_RADIO
				if(transmit_connection != null)
					transmit_connection.post_signal(src, pdaSignal)
				//////////
				src.temp += "<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"
			else
				src.temp = {"<B>ERROR:</B> Insufficient funds. Purchase cancelled.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}
		else
			src.temp = {"<B>ERROR:</B> Login removed mid-transaction. Purchase cancelled.<BR>
							<BR><A href='?src=\ref[src];mainmenu=1'>OK</A>"}

	else if (href_list["mainmenu"])
		src.temp = null
	src.add_fingerprint(usr)
	src.updateUsrDialog()
	return