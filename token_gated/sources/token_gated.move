module token_gated::token_gated_event {
    use sui::transfer;
    use std::vector;
    use sui::object:: {Self, UID};
    use sui::tx_context:: {Self, TxContext};
    use std::string:: {Self, String};


    struct TokenGatedEvent has key, store {
        id: UID,
        event_name: string::String,
        participants: vector<address>
    }

    struct Invitation has key {
        id: UID
    }

    fun init(ctx: &mut TxContext){
        transfer::transfer(
            Invitation{
                id: object::new(ctx)
            },
            tx_context::sender(ctx)
        )
    }

    public entry fun invite(_: &Invitation, guest:address, ctx: &mut TxContext){
        transfer::transfer(
            Invitation{
                id: object::new(ctx)
            },
            guest
        )
    }

    public entry fun create_event(_: &Invitation, event_name: String, ctx: &mut TxContext){
        let event = TokenGatedEvent{
            id: object::new(ctx),
            event_name: event_name,
            participants: vector::empty<address>()
        };
        transfer::share_object(event);
    }

    public entry fun register_for_event(_: &Invitation, event: &mut TokenGatedEvent, ctx: &mut TxContext){
        assert!(vector::contains(&mut event.participants, &tx_context::sender(ctx)) == false, 0);

        vector::push_back(&mut event.participants, tx_context::sender(ctx));
    }

    public fun get_participants(event: &TokenGatedEvent): vector<address>{
        event.participants
    }

}