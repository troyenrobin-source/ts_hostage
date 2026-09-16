RegisterCommand('ts_handcheck', function()
    local ped = PlayerPedId()
    print(('[ts_handcheck] Eigen handsup=%s | animatie=%s | gijzeling=%s'):format(
        tostring(HandsUp.IsRaised()),
        tostring(IsEntityPlayingAnim(ped, Config.HandsUp.Anim.dict, Config.HandsUp.Anim.clip, 3)),
        tostring(Bridge.IsBusy())))
    Bridge.Notify('Eigen handen-omhoog-status staat in F8 bij [ts_handcheck].')
end, false)
