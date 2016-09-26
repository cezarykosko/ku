defmodule KuTest do
  use ExUnit.Case, async: false

  doctest Ku

  @recv_timeout 100

  setup_all do
    Ku.start
    [
      send_body: fn addr -> (fn msg -> send addr, {:body, msg.body} end) end,
      send_meta: fn addr -> (fn msg -> send addr, {:meta, msg.metadata} end) end,
    ]
  end


  describe "Passing arbitrary messages" do
    test "simple message passing", fixture do
      Ku.subscribe "simple-key1", fixture.send_body.(self)
      Ku.subscribe "simple-key1", fixture.send_meta.(self)
      Ku.publish "simple-key1", :body, :meta
      assert_receive {:body, :body}, @recv_timeout
      assert_receive {:meta, :meta}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end

    test "counting down from 3 to 1", fixture do
      step = fn x ->
        Ku.publish Integer.to_string(5 - x.body), x.body - 1
      end
      Ku.subscribe "1", step
      Ku.subscribe "2", step
      Ku.subscribe "3", fixture.send_body.(self)
      Ku.publish "1", 3
      assert_receive {:body, 1}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end

  end

  describe "Correctly dispatching on key patterns" do

    test "plain key matching", fixture do
      Ku.subscribe "key1", fixture.send_body.(self)
      Ku.subscribe "key2", fixture.send_meta.(self)
      Ku.publish "key1", "body1", "meta1"
      Ku.publish "key2", "body2", "meta2"
      Ku.publish "key3", "body3", "meta3"
      assert_receive {:body, "body1"}, @recv_timeout
      refute_receive {:meta, "meta1"}, @recv_timeout
      refute_receive {:body, "body2"}, @recv_timeout
      assert_receive {:meta, "meta2"}, @recv_timeout
      refute_receive {:body, "body3"}, @recv_timeout
      refute_receive {:meta, "body3"}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end

    test "alternative matching", fixture do
      Ku.subscribe "alt-key{1,34}", fixture.send_body.(self)
      Ku.publish "alt-key1", "body1"
      Ku.publish "alt-key2", "body2"
      Ku.publish "alt-key34", "body33"
      assert_receive {:body, "body1"}, @recv_timeout
      assert_receive {:body, "body33"}, @recv_timeout
      refute_receive {:body, "body2"}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end

    test "catchall matching", fixture do
      Ku.subscribe "catchall-key*22", fixture.send_body.(self)
      Ku.publish "catchall-key122", "body1"
      Ku.publish "catchall-key2222", "body2"
      Ku.publish "catchall-key123", "body3"
      Ku.publish "catchall-key12233", "body4"
      assert_receive {:body, "body1"}, @recv_timeout
      assert_receive {:body, "body2"}, @recv_timeout
      refute_receive {:body, "body3"}, @recv_timeout
      refute_receive {:body, "body4"}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end
  end

   describe "Recovering state in case of" do
    test "queue's failure", fixture do
      Ku.subscribe "abc-queue", fixture.send_body.(self)
      Process.exit(Process.whereis(Ku.Queue), :kill)
      :timer.sleep(@recv_timeout)
      Ku.publish "abc-queue", :body
      assert_receive {:body, :body}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end

    test "subscriber's failure", fixture do
      Ku.subscribe "abc-sub", fixture.send_body.(self)
      [pid] = Ku.SubSupervisor.active_subscribers()
      Process.exit(pid, :kill)
      :timer.sleep(@recv_timeout)
      Ku.publish "abc-sub", :body
      assert_receive {:body, :body}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end

    test "subscribers' supervisor failure", fixture do
      Ku.subscribe "abc-supervisor", fixture.send_body.(self)
      Process.exit(Process.whereis(Ku.SubSupervisor), :kill)
      :timer.sleep(@recv_timeout)
      Ku.publish "abc-supervisor", :body
      assert_receive {:body, :body}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end

    test "subscribers' manager failure", fixture do
      Ku.subscribe "abc-manager", fixture.send_body.(self)
      Process.exit(Process.whereis(Ku.SubscriberManager), :kill)
      :timer.sleep(@recv_timeout)
      Ku.publish "abc-manager", :body
      assert_receive {:body, :body}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ku.clear()
    end
   end

end
