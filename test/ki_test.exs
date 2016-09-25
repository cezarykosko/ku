defmodule KiTest do
  use ExUnit.Case, async: false

  doctest Ki

  @recv_timeout 500

  setup_all do
    Ki.start
    [
      send_body: fn addr -> (fn msg -> send addr, {:body, msg.body} end) end,
      send_meta: fn addr -> (fn msg -> send addr, {:meta, msg.metadata} end) end,
    ]
  end


  describe "Passing arbitrary messages" do
    test "simple message passing", fixture do
      Ki.subscribe "simple-key1", fixture.send_body.(self)
      Ki.subscribe "simple-key1", fixture.send_meta.(self)
      Ki.publish "simple-key1", :body, :meta
      assert_receive {:body, :body}, @recv_timeout
      assert_receive {:meta, :meta}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ki.clear()
    end

    test "counting down from 3 to 1", fixture do
      step = fn x ->
        Ki.publish Integer.to_string(5 - x.body), x.body - 1
      end
      Ki.subscribe "1", step
      Ki.subscribe "2", step
      Ki.subscribe "3", fixture.send_body.(self)
      Ki.publish "1", 3
      assert_receive {:body, 1}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ki.clear()
    end

  end

  describe "Correctly dispatching on key patterns" do

    test "plain key matching", fixture do
      Ki.subscribe "key1", fixture.send_body.(self)
      Ki.subscribe "key2", fixture.send_meta.(self)
      Ki.publish "key1", "body1", "meta1"
      Ki.publish "key2", "body2", "meta2"
      Ki.publish "key3", "body3", "meta3"
      assert_receive {:body, "body1"}, @recv_timeout
      refute_receive {:meta, "meta1"}, @recv_timeout
      refute_receive {:body, "body2"}, @recv_timeout
      assert_receive {:meta, "meta2"}, @recv_timeout
      refute_receive {:body, "body3"}, @recv_timeout
      refute_receive {:meta, "body3"}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ki.clear()
    end

    test "alternative matching", fixture do
      Ki.subscribe "alt-key{1,34}", fixture.send_body.(self)
      Ki.publish "alt-key1", "body1"
      Ki.publish "alt-key2", "body2"
      Ki.publish "alt-key34", "body33"
      assert_receive {:body, "body1"}, @recv_timeout
      assert_receive {:body, "body33"}, @recv_timeout
      refute_receive {:body, "body2"}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ki.clear()
    end

    test "catchall matching", fixture do
      Ki.subscribe "catchall-key*22", fixture.send_body.(self)
      Ki.publish "catchall-key122", "body1"
      Ki.publish "catchall-key2222", "body2"
      Ki.publish "catchall-key123", "body3"
      Ki.publish "catchall-key12233", "body4"
      assert_receive {:body, "body1"}, @recv_timeout
      assert_receive {:body, "body2"}, @recv_timeout
      refute_receive {:body, "body3"}, @recv_timeout
      refute_receive {:body, "body4"}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ki.clear()
    end
  end

   describe "Recovering state in case of" do
    test "queue's failure", fixture do
      Ki.subscribe "abc-queue", fixture.send_body.(self)
      Process.exit(Process.whereis(Ki.Queue), :normal)
      Ki.publish "abc-queue", :body
      assert_receive {:body, :body}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ki.clear()
    end

    test "subscriber's failure", fixture do
      pid = Ki.subscribe "abc-sub", fixture.send_body.(self)
      Process.exit(pid, :normal)
      Ki.publish "abc-sub", :body
      assert_receive {:body, :body}, @recv_timeout
      :timer.sleep(@recv_timeout)
      Ki.clear()
    end

    test "subscribers' supervisor failure", fixture do
      Ki.subscribe "abc", fixture.send_body.(self)
      Process.exit(Process.whereis(Ki.SubSupervisor), :normal)
      Ki.publish "abc", :body
      assert_receive {:body, :body}, @recv_timeout
    end
   end

end
