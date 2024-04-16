package eth

// The SubscriptionRTracker maintains a single entry string to keep up with
// the PubSub subscription being used in the NativeRead SDF.
type SubscriptionRTracker struct {
	Subscription string
	Done         bool
}

// NewSubscriptionRTracker returns an RTracker wrapping the
// provided subscription and a "Done" boolean.
func NewSubscriptionRTracker(entry string) *SubscriptionRTracker {
	return &SubscriptionRTracker{Subscription: entry, Done: false}
}

// TryClaim returns true iff the given position is a string and matches the underlying
// subscription ID.
func (s *SubscriptionRTracker) TryClaim(pos any) bool {
	posString, ok := pos.(string)
	return ok && posString == s.Subscription
}

// TrySplit is a no-op for the StaticRTracker in the normal case and moves the subscription
// to the residual in the checkpointing case, marking itself as done to keep the logical checks
// around SDF data loss happy.
func (s *SubscriptionRTracker) TrySplit(frac float64) (primary, residual any, err error) {
	if frac == 0.0 {
		resid := s.Subscription
		s.Subscription = ""
		s.Done = true
		return "", resid, nil
	}
	return s.Subscription, "", nil
}

// GetError is a no-op.
func (s *SubscriptionRTracker) GetError() error {
	return nil
}

// GetProgress returns complete just so the runner doesn't try to do much in the way of
// splitting.
func (s *SubscriptionRTracker) GetProgress() (done float64, remaining float64) {
	done = 1.0
	remaining = 0.0
	return
}

// IsDone returns whether or not the StaticRTracker is complete (e.g. has stopped processing.)
func (s *SubscriptionRTracker) IsDone() bool {
	return s.Done
}

// IsBounded always returns false, as the StaticRTracker represents an unbounded number
// of reads from PubSub.
func (s *SubscriptionRTracker) IsBounded() bool {
	return false
}

// GetRestriction returns the name of the subscription.
func (s *SubscriptionRTracker) GetRestriction() any {
	return s.Subscription
}
