require 'flipper/expression'

# Property-based check that empty group detection and pruning honor their
# contracts, verified against the evaluator itself. For seeded random trees
# (biased toward empty Any/All groups):
#
#   - expressions without empty groups prune to themselves
#   - pruning never broadens: no context excluded by the original may be
#     included by the pruned expression
#   - pruning to nil only happens when the original is a constant
#   - always_true? implies the expression evaluates true in every context
#
# The seed is fixed for determinism; override with FUZZ_SEED/FUZZ_TREES for
# exploratory runs.
RSpec.describe Flipper::Expression do
  SEED = (ENV["FUZZ_SEED"] || 20260728).to_i
  TREES = (ENV["FUZZ_TREES"] || 1500).to_i

  PLANS = %w[basic pro enterprise].freeze

  CONTEXTS = PLANS.flat_map do |plan|
    (0..50).step(10).map { |age| {properties: {"plan" => plan, "age" => age}} }
  end.freeze

  def random_leaf(rng)
    case rng.rand(4)
    when 0 then {"Equal" => [{"Property" => ["plan"]}, PLANS[rng.rand(3)]]}
    when 1 then {"NotEqual" => [{"Property" => ["plan"]}, PLANS[rng.rand(3)]]}
    when 2 then {"GreaterThan" => [{"Property" => ["age"]}, rng.rand(50)]}
    else        {"LessThan" => [{"Property" => ["age"]}, rng.rand(50)]}
    end
  end

  def random_tree(rng, depth)
    return random_leaf(rng) if depth <= 0 || rng.rand < 0.25

    operator = rng.rand < 0.5 ? "Any" : "All"
    children = Array.new(rng.rand(4)) { random_tree(rng, depth - 1) }
    {operator => children}
  end

  def evaluate_all(expression)
    CONTEXTS.map { |context| !!expression.evaluate(context) }
  end

  def surviving_empty_groups(expression, parent = nil)
    return [] unless expression.is_a?(described_class)

    found = expression.group? && expression.args.empty? ? [[expression, parent]] : []
    found + expression.args.flat_map { |arg| surviving_empty_groups(arg, expression) }
  end

  it "prunes without ever broadening the expression" do
    rng = Random.new(SEED)

    TREES.times do
      tree = random_tree(rng, 4)
      expression = described_class.build(tree)
      failure = "seed=#{SEED} tree=#{tree.inspect}"

      values = evaluate_all(expression)
      pruned = expression.prune_empty_groups

      if expression.always_true?
        expect(values).to all(be(true)), "#{failure} always_true? but not always true"
      end

      unless expression.empty_groups?
        expect(pruned).to eq(expression), "#{failure} pruning changed a clean expression"
        next
      end

      if pruned.nil?
        expect(values.uniq.size).to eq(1), "#{failure} pruned to nil but original is not constant"
      else
        evaluate_all(pruned).zip(values).each do |after, before|
          expect(after && !before).to be(false), "#{failure} pruning broadened the expression"
        end

        surviving_empty_groups(pruned).each do |group, parent|
          expect(group.any? && parent&.all?).to be(true),
            "#{failure} retained a removable empty group"
        end
      end
    end
  end
end
