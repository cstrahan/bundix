require 'bundler'

class GemfileDependencyTree
  Spec = Struct.new(:name, :groups, :source, :version, :dependencies)

  def self.run(options)
    definitions = Bundler::Dsl.evaluate(options.fetch(:gemfile), nil, {})
    specs =
      if options.fetch(:cache)
        definitions.resolve_with_cache!
      else
        definitions.resolve_remotely!
      end
    definitions.lock(Bundler.default_lockfile) if options.fetch(:lock)

    result = {}
    definitions.dependencies.each do |dependency|
      new(dependency, specs, dependency.groups).run([], result)
    end

    result
  end

  def initialize(dep, specs, groups)
    @dep = dep
    @spec = specs.find{|s| s.name == dep.name }
    @groups = groups.map(&:to_s)
    @children = dependencies.map{|d| self.class.new(d, specs, groups) }
  end

  def run(seen = [], result = {})
    children = @children.reject{|c| seen.include?(c.name) }
    add_group(result, @spec)

    children.each do |child|
      seen << child.name
      child.run(seen, result)
    end

    result
  end

  def name
    @spec.name
  end

  private

  def add_group(result, dep)
    if result[dep.name]
      result[dep.name].groups |= @groups
    else
      result[dep.name] = Spec.new(
        dep.name,
        @groups,
        dep.source,
        dep.version.to_s,
        dependencies.map(&:name)
      )
    end
  end

  def dependencies
    @spec.dependencies.reject{|d| d.type == :development }
  end
end
