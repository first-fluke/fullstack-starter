---
title: Use @tanstack/query for Automatic Deduplication
impact: MEDIUM-HIGH
impactDescription: automatic deduplication
tags: client, tanstack-query, react-query, deduplication, data-fetching
---

## Use @tanstack/query for Automatic Deduplication

@tanstack/query (React Query) enables request deduplication, caching, and revalidation across component instances.

**Incorrect (no deduplication, each instance fetches):**

```tsx
function UserList() {
  const [users, setUsers] = useState([])
  useEffect(() => {
    fetch('/api/users')
      .then(r => r.json())
      .then(setUsers)
  }, [])
}
```

**Correct (multiple instances share one request):**

```tsx
import { useQuery } from '@tanstack/react-query'

function UserList() {
  const { data: users } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json())
  })
}
```

**For immutable/static data:**

```tsx
import { useQuery } from '@tanstack/react-query'

function StaticContent() {
  const { data } = useQuery({
    queryKey: ['config'],
    queryFn: fetchConfig,
    staleTime: Infinity,
    gcTime: Infinity
  })
}
```

**For mutations:**

```tsx
import { useMutation, useQueryClient } from '@tanstack/react-query'

function UpdateButton() {
  const queryClient = useQueryClient()
  const { mutate } = useMutation({
    mutationFn: updateUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user'] })
    }
  })
  return <button onClick={() => mutate()}>Update</button>
}
```

Reference: [https://tanstack.com/query](https://tanstack.com/query)
