# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     TypingApp.Repo.insert!(%TypingApp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

user = TypingApp.Repo.insert!(%TypingApp.Accounts.User{
  name: "user",
  email: "user@example.com",
})

TypingApp.Repo.insert!(%TypingApp.Games.UserProgress{
  user_id: user.id,
  current_level: 1,
  total_score: 0,
  best_wpm: 0.0,
  games_played: 0
})
