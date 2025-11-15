# Poll Interval Dynamic Adjustment Demo

This demo shows how the Flipper poller dynamically adjusts its polling interval based on the `poll-interval` header from the server, and how it responds to the `poll-shutdown` header.

## Files

- `server.rb` - Test server that responds with configurable headers
- `client.rb` - Client that polls the server and logs interval changes
- `README.md` - This file

## How to Run

### Terminal 1: Start the Server

```bash
bundle exec ruby examples/cloud/poll_interval/server.rb
```

The server will start on http://localhost:3000 and show a prompt where you can control what headers to send.

### Terminal 2: Start the Client

```bash
bundle exec ruby examples/cloud/poll_interval/client.rb
```

The client will start polling the server every 10 seconds (the minimum) and log all activity.

## Testing Scenarios

### 1. Change Poll Interval

In the **server terminal**, type a number to set the poll interval:

```
> 20
```

In the **client terminal**, you'll see:

```
[HH:MM:SS] WARN: ⚠️  INTERVAL CHANGED: 10.0s → 20.0s
```

The client will now poll every 20 seconds instead of 10.

### 2. Try an Invalid Interval (Below Minimum)

In the **server terminal**:

```
> 5
```

In the **client terminal**, you'll see a warning:

```
Flipper::Cloud poll interval must be greater than or equal to 10 but was 5.0. Setting interval to 10.
```

The interval will remain at 10 seconds (the minimum).

### 3. Trigger Shutdown

In the **server terminal**:

```
> shutdown
```

In the **client terminal**, you'll see:

```
[HH:MM:SS] WARN: Shutdown requested by server via poll-shutdown header
[HH:MM:SS] WARN: Poller stopped
[HH:MM:SS] WARN: Poller thread is no longer running
```

The poller will stop gracefully.

### 4. Reset Headers

In the **server terminal**:

```
> reset
```

The server will stop sending special headers. The client will continue with its current interval.

## What You'll Learn

- How `poll-interval` header dynamically adjusts polling frequency
- How `poll-shutdown` header gracefully stops the poller
- How minimum interval enforcement works (10 seconds minimum)
- How the poller continues working even if the server returns errors
- Real-time logging of poller events via instrumentation

## Implementation Details

The poller checks response headers in the `ensure` block of the `sync` method, which means:

- Interval adjustments happen even if the sync fails with an error
- Shutdown signals are never missed, even during failures
- The poller is resilient to network issues

The `interval=` setter handles all validation:

- Type conversion via `Flipper::Typecast.to_float`
- Minimum enforcement (10 seconds)
- Warning messages for invalid values
