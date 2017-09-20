-module(aec_blocks_tests).

-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

-include("common.hrl").
-include("blocks.hrl").

-define(TEST_MODULE, aec_blocks).

-define(TEST_HASH, <<12345:?TXS_HASH_BYTES/unit:8>>).


new_block_test_() ->
    {setup,
     fun() ->
             meck:new(aec_trees, [passthrough]),
             meck:expect(aec_trees, all_trees_hash, 1, <<>>),
             meck:expect(aec_trees, root_hash, fun(_) -> {ok, ?TEST_HASH} end)
     end,
     fun(_) ->
             ?assert(meck:validate(aec_trees)),
             meck:unload(aec_trees)
     end,
     {"Generate new block with given txs and 0 nonce",
      fun() ->
              PrevBlock = #block{height = 11, target = 17},
              BlockHeader = ?TEST_MODULE:to_header(PrevBlock),

              {ok, NewBlock} = ?TEST_MODULE:new(PrevBlock, [], #trees{}),

              ?assertEqual(12, ?TEST_MODULE:height(NewBlock)),
              ?assertEqual(aec_sha256:hash(BlockHeader),
                           ?TEST_MODULE:prev_hash(NewBlock)),
              ?assertEqual([], NewBlock#block.txs),
              ?assertEqual(?TEST_HASH, NewBlock#block.txs_hash),
              ?assertEqual(17, NewBlock#block.target),
              ?assertEqual(1, NewBlock#block.version)
      end}}.

network_serialization_test() ->
    Block = #block{trees = #trees{accounts = foo}},
    {ok, SerializedBlock} = ?TEST_MODULE:serialize_for_network(Block),
    {ok, DeserializedBlock} =
        ?TEST_MODULE:deserialize_from_network(SerializedBlock),
    ?assertEqual(Block#block{trees = #trees{}}, DeserializedBlock),
    ?assertEqual({ok, SerializedBlock},
                 ?TEST_MODULE:serialize_for_network(DeserializedBlock)).

hash_test() ->
    Block = #block{},
    {ok, SerializedHeader} =
        aec_headers:serialize_for_network(?TEST_MODULE:to_header(Block)),
    ?assertEqual({ok, aec_sha256:hash(SerializedHeader)},
                 ?TEST_MODULE:hash_internal_representation(Block)).

create_state_tree() ->
    {ok, AccountsTree} = aec_accounts:empty(),
    StateTrees0 = #trees{},
    aec_trees:set_accounts(StateTrees0, AccountsTree).

-endif.
