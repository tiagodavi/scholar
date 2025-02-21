defmodule Scholar.Cluster.KMeansTest do
  use Scholar.Case, async: true
  alias Scholar.Cluster.KMeans
  doctest KMeans

  @key Nx.Random.key(42)

  describe "fit, predict, and transform" do
    test "fit and predict without weights" do
      model =
        KMeans.fit(Nx.tensor([[1, 2], [2, 4], [1, 3], [2, 5]]),
          num_clusters: 2,
          key: @key
        )

      assert model.clusters == Nx.tensor([[1.0, 2.5], [2.0, 4.5]])
      assert model.inertia == Nx.tensor(1.0, type: {:f, 32})
      assert model.labels == Nx.tensor([0, 1, 0, 1])
      assert model.num_iterations == Nx.tensor(2)

      predictions = KMeans.predict(model, Nx.tensor([[1.9, 4.3], [1.1, 2.0]]))
      assert predictions == Nx.tensor([1, 0])
    end

    test "fit and predict without weights and :init set as :random" do
      model =
        KMeans.fit(Nx.tensor([[1, 2], [2, 4], [1, 3], [2, 5]]),
          num_clusters: 2,
          key: @key,
          init: :random
        )

      assert model.clusters == Nx.tensor([[2.0, 4.5], [1.0, 2.5]])
      assert model.inertia == Nx.tensor(1.0, type: {:f, 32})
      assert model.labels == Nx.tensor([1, 0, 1, 0])
      assert model.num_iterations == Nx.tensor(3)

      predictions = KMeans.predict(model, Nx.tensor([[1.9, 4.3], [1.1, 2.0]]))
      assert predictions == Nx.tensor([0, 1])
    end

    test "fit and predict with weights as a list" do
      model =
        KMeans.fit(Nx.tensor([[1, 2], [2, 4.25], [1, 3], [2, 5]]),
          num_clusters: 2,
          key: @key,
          weights: [1, 2, 3, 4]
        )

      assert model.clusters == Nx.tensor([[1.0, 2.75], [2.0, 4.75]])
      assert model.inertia == Nx.tensor(1.5, type: {:f, 32})
      assert model.labels == Nx.tensor([0, 1, 0, 1])
      assert model.num_iterations == Nx.tensor(2)

      predictions = KMeans.predict(model, Nx.tensor([[1.9, 4.3], [1.1, 2.0]]))
      assert predictions == Nx.tensor([1, 0])
    end

    test "fit and predict with weights as a tensor" do
      model =
        KMeans.fit(Nx.tensor([[1, 2], [2, 4.25], [1, 3], [2, 5]]),
          num_clusters: 2,
          key: @key,
          weights: Nx.tensor([1, 2, 3, 4], type: {:f, 32})
        )

      assert model.clusters == Nx.tensor([[1.0, 2.75], [2.0, 4.75]])
      assert model.inertia == Nx.tensor(1.5, type: {:f, 32})
      assert model.labels == Nx.tensor([0, 1, 0, 1])
      assert model.num_iterations == Nx.tensor(2)

      predictions = KMeans.predict(model, Nx.tensor([[1.9, 4.3], [1.1, 2.0]]))
      assert predictions == Nx.tensor([1, 0])
    end

    test "transform" do
      model =
        KMeans.fit(Nx.tensor([[1, 2], [2, 4], [1, 3], [2, 5]]),
          num_clusters: 2
        )

      assert Nx.sort(KMeans.transform(model, Nx.tensor([[1.0, 2.5]])), axis: 1) ==
               Nx.tensor([[0.0, 2.2360680103302]])
    end
  end

  describe "errors" do
    test "when :num_clusters is not provided" do
      x = Nx.tensor([[1, 2], [3, 4], [5, 6]])

      assert_raise NimbleOptions.ValidationError,
                   "required :num_clusters option not found, received options: []",
                   fn ->
                     KMeans.fit(x)
                   end
    end

    test "when :num_clusters is invalid" do
      x = Nx.tensor([[1, 2], [3, 4], [5, 6]])

      assert_raise ArgumentError,
                   "invalid value for :num_clusters option: expected positive integer between 1 and 3, got: 4",
                   fn ->
                     KMeans.fit(x, num_clusters: 4)
                   end

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :num_clusters option: expected positive integer, got: 2.0",
                   fn ->
                     KMeans.fit(x, num_clusters: 2.0)
                   end

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :num_clusters option: expected positive integer, got: -1",
                   fn ->
                     KMeans.fit(x, num_clusters: -1)
                   end
    end

    test "when training vector size is invalid" do
      x = Nx.tensor([5, 6])

      assert_raise ArgumentError,
                   "expected input tensor to have shape {n_samples, n_features}, got tensor with shape: {2}",
                   fn -> KMeans.fit(x, num_clusters: 2) end
    end

    test "when :max_iterations is not a positive integer" do
      x = Nx.tensor([[1, 2], [3, 4]])

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :max_iterations option: expected positive integer, got: 0",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, max_iterations: 0)
                   end

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :max_iterations option: expected positive integer, got: 200.0",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, max_iterations: 200.0)
                   end
    end

    test "when :num_runs is not a positive integer" do
      x = Nx.tensor([[1, 2], [3, 4]])

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :num_runs option: expected positive integer, got: 0",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, num_runs: 0)
                   end

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :num_runs option: expected positive integer, got: 10.0",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, num_runs: 10.0)
                   end
    end

    test "when :tol is not a non-negative number" do
      x = Nx.tensor([[1, 2], [3, 4]])

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :tol option: expected positive number, got: -0.1",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, tol: -0.1)
                   end
    end

    test "when :init is neither :random nor a :k_means_plus_plus" do
      x = Nx.tensor([[1, 2], [3, 4]])

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :init option: expected one of [:k_means_plus_plus, :random], got: :abc",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, init: :abc)
                   end
    end

    test "when :weights is not a list of positive numbers" do
      x = Nx.tensor([[1, 2], [3, 4]])

      assert_raise ArgumentError,
                   "invalid value for :weights option: expected list or tensor of positive numbers of size 2, got: [1, 2, 3]",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, weights: [1, 2, 3])
                   end

      assert_raise NimbleOptions.ValidationError,
                   "invalid value for :weights option: expected weights to be a flat tensor or a flat list, got: {1, 2}",
                   fn ->
                     KMeans.fit(x, num_clusters: 2, weights: {1, 2})
                   end
    end
  end
end
