package signal

import (
	"github.com/cloudwebrtc/go-protoo/peer"
	"github.com/cloudwebrtc/go-protoo/transport"
	"github.com/pion/ion/log"
)

func newPeer(id string, t *transport.WebSocketTransport) *Peer {
	return &Peer{
		Peer: *peer.NewPeer(id, t),
	}
}

func getPeer(rid, id string) *peer.Peer {
	room := getRoom(rid)
	if room != nil {
		return room.GetPeer(id)
	}
	return nil
}

type Peer struct {
	peer.Peer
}

func (p *Peer) On(event, listener interface{}) {
	p.Peer.On(event, listener)
}

func (c *Peer) Request(method string, data map[string]interface{}) {
	c.Peer.Request(method, data, accept, reject)
}

func (c *Peer) Close() {
	c.Peer.Close()
}

func accept(data map[string]interface{}) {
	log.Infof("peer accept data=%v", data)
}

func reject(errorCode int, errorReason string) {
	log.Infof("reject errorCode=%v errorReason=%v", errorCode, errorReason)
}
