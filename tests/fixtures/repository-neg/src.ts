// WHEN NOT TO APPLY: data access is already isolated behind a repository
// interface; the service only depends on that abstraction. Nothing to extract.
interface User {
  id: number;
  name: string;
}

export interface UserRepo {
  findById(id: number): User | null;
}

export function makeUserRepo(): UserRepo {
  const users: User[] = [{ id: 1, name: "Ada" }];
  return {
    findById(id: number): User | null {
      return users.find((u) => u.id === id) || null;
    },
  };
}

export function greet(repo: UserRepo, id: number): string {
  const u = repo.findById(id);
  return u ? "Hello " + u.name : "unknown";
}
