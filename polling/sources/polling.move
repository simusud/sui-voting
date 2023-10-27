module polling::onchain_poll {
    use sui::transfer;
    use std::vector;
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};

    const EINSUFFICIENT_REGISTRATION_FEE: u64 = 2;

    struct PollAdmin has key{
        id: UID,
        admin: address
    }

    struct PollingOption has key, store{
        id: UID,
        option_id: u64,
        polling_description: vector<u64>,
        vote_count: u64
    }

    struct Poll has key, store{
        id: UID,
        options: vector<PollingOption>,
        voters: vector<address>
    }

    struct Membership has key{
        id: UID
    }

    fun init(ctx: &mut TxContext){
       transfer::transfer(
           PollAdmin{
               id: object::new(ctx),
               admin: tx_context::sender(ctx)
           }, tx_context::sender(ctx)
       );

        transfer::transfer(
           Membership{
               id: object::new(ctx),
           }, tx_context::sender(ctx)
       );
    }

    public entry fun register(payment: Coin<SUI>, poll_admin: &PollAdmin, ctx: &mut TxContext){
        // in order to pass SUI first split the token amount for payment:
        // sui client split-coin --coin-id <object ID of the coin to be split> --amounts 1 --gas-budget 10000000
        // after this pass the object ID of the newly split SUI as the param payment
        // sui client call --function 'register' --module 'onchain_poll' --package 0x35c0a5f11240b0edb7c9724fc76584f843921f2b6de4819e714fa1398c5fb19f --args 0x3063e2a2b2e4c046a9102de89ba94ce1f69129edb3baf7adb4278e0a708f570e 0xa6fc1595673b92cedf7e5324cdeded02cf9f97cc415b5bcce948d8af125c89ef --gas-budget 10000000

        assert!(coin::value(&payment) >= 1, EINSUFFICIENT_REGISTRATION_FEE);

        transfer::transfer(
            Membership{
                id: object::new(ctx)
            },
            tx_context::sender(ctx)
        );
        transfer::public_transfer(payment, poll_admin.admin);
    }

    public entry fun create_poll(_: &Membership, options: vector<vector<u64>>, ctx: &mut TxContext){
        // only member can create poll
        // psss vector as: '[[1], [2], [3]]' through cli
        let poll_options: vector<PollingOption> = vector::empty<PollingOption>();

        let length = vector::length(& options);
        let option_id: u64 = 1;
        let i = 0;
        loop{
            if (i >= length) break;
            let poll_option = PollingOption{
                id: object::new(ctx),
                option_id: option_id,
                polling_description: *vector::borrow(&options, i),
                vote_count: 0
            };
            vector::push_back(&mut poll_options, poll_option);
            i = i + 1;
            option_id = option_id + 1;
        };
        
        transfer::share_object(Poll{
            id: object::new(ctx), options: poll_options, voters: vector::empty()
        });
    }

    public entry fun add_poll_option(_: &Membership, poll: &mut Poll, options:vector<vector<u64>>, ctx: &mut TxContext){
        let poll_options: vector<PollingOption> = vector::empty<PollingOption>();
        let length = vector::length(& options);
        let prev_options = vector::length(& poll.options);
        let option_id: u64 = (prev_options + 1);
        let i = 0;
        loop{
            if (i >= length) break;
            let poll_option = PollingOption{
                id: object::new(ctx),
                option_id: option_id,
                polling_description: *vector::borrow(&options, i),
                vote_count: 0
            };
            vector::push_back(&mut poll_options, poll_option);
            i = i + 1;
            option_id = option_id + 1;
        };
        vector::append(&mut poll.options, poll_options);
    }

    public entry fun vote(_: &Membership, poll: &mut Poll, option_no: u64, ctx: &mut TxContext){
        // prevent double votting
        assert!((option_no > 0) && (option_no <= vector::length(& poll.options)), 0);
        assert!(vector::contains(&mut poll.voters, &tx_context::sender(ctx)) == false, 0);

        let selected_option = vector::borrow_mut(&mut poll.options, option_no-1);
        selected_option.vote_count = selected_option.vote_count + 1;
        vector::push_back(&mut poll.voters, tx_context::sender(ctx))
    }

    public fun get_poll_result(poll: &PollingOption): u64{
        poll.vote_count
    }

}

// '[[1], [2], [3]]'

// sui client call --function 'add_poll_option' --module 'onchain_poll' --package 0x35c0a5f11240b0edb7c9724fc76584f843921f2b6de4819e714fa1398c5fb19f --args 0xb0487f5a28a4accb5ce8a330d725b4a601dd62bd7dd7b47e79e62b16d27e6599 0x402677443c5952ed5c1bbbf9df073960e5fa5f614027c98f5594f29d26294d09 '[[5],[6]]' --gas-budget 10000000
// sui client call --function 'register_for_event' --module 'token_gated_event' --package 0x7bd3383edb638c2639d012fbdc1722fc3deeb373c0f13658479ec78b5a7b523a --args 0x85e8fd1df593139957abfd79a08519375549574b606108a95aacd0e4ac4fbbd6 0x156a21ac949334560fc957d8acf5d96e71ac86dc0901a3a38f933b9248d566c8  --gas-budget 10000000