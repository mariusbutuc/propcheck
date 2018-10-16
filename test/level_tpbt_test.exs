defmodule PropCheck.Test.LevelTest do
  use PropCheck
  use ExUnit.Case

  require Logger

  alias PropCheck.Test.Level
  alias PropCheck.TargetedPBT

  #######################################################################
  # Generators
  #######################################################################

  def step(), do: oneof([:left, :right, :up, :down])

  def path_gen(), do: list(step())

  def path_sa(), do: %{first: path_gen(), next: path_next()}

  @spec path_next() :: ([Level.step], any() -> PropCheck.BasicTypes.t)
  def path_next() do
    fn (prev_path, _temperature) when is_list(prev_path) ->
      let next_steps <- vector(20, step()), do:
        prev_path ++ next_steps
    end
  end

  #######################################################################
  # Properties
  #######################################################################

  def distance({x1, y1}, {x2, y2}), do:
    :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))

  # def prop_exit(level_data) ->
  #   Level = build_level(level_data),
  #   #{entrance := Entrance} = Level,
  #   ?FORALL(Path, path(),
  #           case follow_path(Entrance, Path, Level) of
  #             {exited, _} -> false;
  #             _ -> true
  #           end).

  def prop_exit(level_data) do
    level = Level.build_level(level_data)
    %{entrance: entrance} = level
    forall path <- path_gen() do
      case Level.follow_path(entrance, path, level) do
        {:exited, _} -> false
        _ -> true
      end
    end
  end

  property "Default PBT Level 0" do
    prop_exit(Level.level0())
  end

  property "Default PBT Level 1" do
    prop_exit(Level.level1())
  end

  # prop_exit_targeted(LevelData) ->
  #   Level = build_level(LevelData),
  #   #{entrance := Entrance} = Level,
  #   #{exit := Exit} = Level,
  #   ?FORALL_SA(Path, ?TARGET(path_sa()),
  #              case follow_path(Entrance, Path, Level) of
  #                {exited, _Pos} -> false;
  #                Pos ->
  #                  case length(Path) > 500 of
  #                    true -> proper_sa:reset(), true;
  #                    _ ->
  #                      UV = distance(Pos, Exit),
  #                      ?MINIMIZE(UV),
  #                      true
  #                  end
  #              end).


  property "Target PBT Level 1", [:verbose] do
    level_data = Level.level1()
    level = Level.build_level(level_data)
    %{entrance: entrance} = level
    %{exit: exit_pos} = level
    forall_sa path <- target(path_sa()) do
      case Level.follow_path(entrance, path, level) do
        {:exited, _} -> false
        pos ->
          if length(path) > 500 do
            :proper_sa.reset()
            true
          else
            uv = distance(pos, exit_pos)
            minimize(uv)
            true
          end
      end
      |> collect(length(path))
    end
  end

  property "Exists Target PBT Level 1", [:verbose] do
    level_data = Level.level0()
    level = Level.build_level(level_data)
    %{entrance: entrance} = level
    %{exit: exit_pos} = level
    exists path <- path_sa() do
      case Level.follow_path(entrance, path, level) do
        {:exited, _} -> false
        pos ->
          uv = distance(pos, exit_pos)
          minimize(uv)
          true
      end
    end
  end


end
