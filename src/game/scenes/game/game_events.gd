class_name GameEvents
extends Resource

@warning_ignore("unused_signal") signal ev_game_state_changed(from_state: String, to_state: String)
@warning_ignore("unused_signal") signal ev_pawn_died(player_id: int, lives_left: int)
@warning_ignore("unused_signal") signal ev_player_lost(player_id: int)
@warning_ignore("unused_signal") signal ev_match_over(winner_id: int)
