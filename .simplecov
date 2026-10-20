SimpleCov.start do
  enable_coverage :branch            # track branches as well as lines
  cover "{app,lib}/**/*.rb"          # report on these files, even if never loaded

  coverage :line do
    maximum_drop 1                   # ...or when coverage drops more than 1%
  end

  coverage :branch, maximum_drop: 1, ignore: :implicit_else
end

