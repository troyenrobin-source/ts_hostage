if not TSBridgeGuard.Await() then return end
RegisterCommand('ts_handcheck', function()
    local ped = PlayerPedId()
    print((TSL('diagnostics_ts_handcheck_eigen_handsup_animatie_gijzeling')):format(
        tostring(HandsUp.IsRaised()),
        tostring(IsEntityPlayingAnim(ped, Config.HandsUp.Anim.dict, Config.HandsUp.Anim.clip, 3)),
        tostring(Bridge.IsBusy())))
    Bridge.Notify(TSL('diagnostics_eigen_handen_omhoog_status_staat_in_bij'))
end, false)
