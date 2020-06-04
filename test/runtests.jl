using Test, Seis, SeisTau

@testset "SeisTau" begin
    @testset "Travel time" begin
        let t = Trace(0, 1, 2)
            @testset "Phase supplied" begin
                @test_throws ArgumentError travel_time(t, "P")
                t.evt.lon, t.evt.lat, t.evt.dep = 0, 0, 0
                t.sta.lon, t.sta.lat = 10, 10
                @test travel_time(t, "P") == travel_time(t.evt, t.sta, "P")
                arr = travel_time(t, "P")
                @test length(arr) == 1
                @test arr[1].time ≈ 200.405669 atol=0.0001
            end
            @testset "Using picks" begin
                @test travel_times(t) == []
                t.picks.P = (0, "P")
                @test travel_times(t) == [travel_time(t, "P")]
                t′ = deepcopy(t)
                # Ignore unnamed picks
                t′.picks.X = 1
                @test travel_times(t′) == travel_times(t)
                # Ignore empty but not missing names
                t′.picks.S = 2, ""
                @test travel_times(t′) == travel_times(t)
                # Ignore picks with the wrong kind of name
                t′.picks.sS = 3, "asS"
                @test travel_times(t′) == travel_times(t)
            end
            @testset "Default phases" begin
                @test travel_time(t) == travel_time(t, "ttall")
            end
        end
    end

    @testset "Path" begin
        let t = Trace(0, 1, 2)
            @test_throws ArgumentError path(t)
            @test_throws ArgumentError path(t.evt, t.sta)
            t.evt.lon, t.evt.lat, t.evt.dep = 0, 0, 0
            t.sta.lon, t.sta.lat = 0, 80
            @test path(t) == path(t, "ttall")
            @test path(t) == path(t.evt, t.sta)
            arr = path(t, "P")
            @test length(arr) == 1
            @test arr[1].name == "P"
            @test !isempty(arr[1].radius)
            @test !isempty(arr[1].lon)
        end
    end

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

    @testset "Checking" begin
        let e = Seis.Event(), s = Seis.Station(), t = Trace(0, 1, 2)
            t.evt = e
            t.sta = s
            @test_throws ArgumentError SeisTau._check_headers_taup(e, s)
            @test_throws ArgumentError SeisTau._check_headers_taup(t)
            e.lon, e.lat, e.dep = 0, 0, 0
            s.lon, s.lat = 10, 10
            @test SeisTau._check_headers_taup(e, s) === nothing
            @test SeisTau._check_headers_taup(t) === nothing
        end
    end
end
