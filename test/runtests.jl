using Test, Seis, SeisTau

@testset "SeisTau" begin
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

    @testset "Sphere" begin
        # Calculating geographic travel times using elliptical and spherical Earth
        let t = Trace(0, 1, 2)
            t.evt.lon = t.evt.lat = t.sta.lon = t.evt.dep = 0
            t.sta.lat = 45
            tt = travel_time(t, "P") # WGS84 ellipsoid
            @test tt[1].delta ≈ 44.78 atol=0.01
            tt′ = travel_time(t, "P", sphere=true) # Sphere
            @test tt′[1].delta == 45.0
        end
    end
end
