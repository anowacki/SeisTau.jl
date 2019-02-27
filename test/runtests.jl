using Test, Seis, SeisTau

@testset "Picks" begin
    # Adding travel time picks from TauPy
    let t = Trace(0, 1, rand(2))
        # Can't add travel times without correct geometry
        @test_throws ArgumentError add_picks!(t, "S")
        t.evt.lon, t.evt.lat, t.evt.dep = 0, 0, 0
        t.sta.lon, t.sta.lat = 10, 10
        add_picks!(t, "Sn", model="ak135")
        @test picks(t)[end].time ≈ 358.4306 atol=0.0001
        @test picks(t)[end].name == "Sn"
    end
end
