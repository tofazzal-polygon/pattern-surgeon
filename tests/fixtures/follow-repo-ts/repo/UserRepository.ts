export interface User { id: string; name: string }

export class UserRepository {
  async byId(id: string): Promise<User | null> {
    const r = await fetch(`/api/users/${id}`);
    return r.ok ? (await r.json()) as User : null;
  }
}
