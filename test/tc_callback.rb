require 'test_common'

class SimpleCb
  include Bud

  state do
    scratch :t1
    callback :c1
  end

  bloom do
    c1 <= t1
  end
end

class CallbackAtNext
  include Bud

  state do
    scratch :t1
    callback :c1
  end

  bloom do
    c1 <+ t1
  end
end

class CallbackTest < Test::Unit::TestCase
  class Counter
    attr_reader :cnt

    def initialize
      @cnt = 0
    end

    def bump
      @cnt += 1
    end
  end

  def test_simple_cb
    c = SimpleCb.new
    call_tick = Counter.new
    tuple_tick = Counter.new
    c.register_callback(:c1) do |t|
      call_tick.bump
      t.length.times do
        tuple_tick.bump
      end
    end

    c.run_bg
    c.sync_do
    assert_equal(0, call_tick.cnt)
    assert_equal(0, tuple_tick.cnt)
    c.sync_do {
      c.t1 <+ [[5, 10]]
    }
    assert_equal(1, call_tick.cnt)
    assert_equal(1, tuple_tick.cnt)
    c.sync_do {
      c.t1 <+ [[10, 15], [20, 25]]
    }
    assert_equal(2, call_tick.cnt)
    assert_equal(3, tuple_tick.cnt)
    c.stop_bg
  end

  def test_cb_at_next
    c = CallbackAtNext.new
    c.run_bg
    tick = Counter.new
    c.register_callback(:c1) do |t|
      tick.bump
    end

    c.sync_do {
      c.t1 <+ [[20, 30]]
    }
    assert_equal(0, tick.cnt)
    c.sync_do
    assert_equal(1, tick.cnt)

    c.stop_bg
  end
end