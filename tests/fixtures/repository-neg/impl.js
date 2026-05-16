// WHEN NOT TO APPLY: data access is already isolated behind a repository
// interface; the service only depends on that abstraction. Nothing to extract.
function makeUserRepo() {
  const users = [{ id: 1, name: "Ada" }];
  return {
    findById(id) {
      return users.find((u) => u.id === id) || null;
    },
  };
}

function greet(repo, id) {
  const u = repo.findById(id);
  return u ? "Hello " + u.name : "unknown";
}

module.exports = { makeUserRepo, greet };
