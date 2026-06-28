/*
 * © 2025 Sharon Aicler (saichler@gmail.com)
 *
 * Layer 8 Ecosystem is licensed under the Apache License, Version 2.0.
 * You may obtain a copy of the License at:
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
	"encoding/base64"
	"github.com/saichler/l8bus/go/overlay/health"
	"github.com/saichler/l8bus/go/overlay/vnet"
	"github.com/saichler/l8bus/go/overlay/vnic"
	"github.com/saichler/l8common/go/common"
	"github.com/saichler/l8types/go/ifs"
	"github.com/saichler/l8types/go/sec"
	"github.com/saichler/l8utils/go/utils/ipsegment"
	"github.com/saichler/l8web/go/web/server"
	"strconv"
)

func main() {
	resources := common.CreateResources("vnet-book", false)
	net := vnet.NewVNet(resources)
	net.Start()
	resources.Logger().Info("vnet started!")
	startWebServer(3773, "/data/book")
}

func startWebServer(port int, cert string) {

	nic1 := createVnic(43434)

	domain, private, _ := nic1.Resources().Certificate()
	if domain == "" || private == "" {
		d, p, _ := sec.CreateCertBundle()
		domainBytes, _ := base64.StdEncoding.DecodeString(d)
		privateBytes, _ := base64.StdEncoding.DecodeString(p)
		domain = string(domainBytes)
		private = string(privateBytes)
	}

	serverConfig := &server.RestServerConfig{
		Host:           ipsegment.MachineIP,
		Port:           int(nic1.Resources().SysConfig().WebConfig.WebPort),
		Authentication: true,
		CertDomain:     domain,
		CertPrivate:    private,
		Prefix:         nic1.Resources().WebPrefix(),
	}

	svr, err := server.NewRestServer(serverConfig)
	if err != nil {
		panic(err)
	}

	hs, ok := nic1.Resources().Services().ServiceHandler(health.ServiceName, 0)
	if ok {
		ws := hs.WebService()
		svr.RegisterWebService(ws, nic1)
	}

	//Activate the webpoints service
	sla := ifs.NewServiceLevelAgreement(&server.WebService{}, ifs.WebService, 0, false, nil)
	sla.SetArgs(svr)
	nic1.Resources().Services().Activate(sla, nic1)

	nic1.Resources().Logger().Info("Web Server Started!")

	svr.Start()
}

func createVnic(vnet uint32) ifs.IVNic {
	resources := common.CreateResources("web-"+strconv.Itoa(int(vnet)), false)
	resources.SysConfig().VnetPort = vnet

	nic := vnic.NewVirtualNetworkInterface(resources, nil)
	nic.Resources().SysConfig().KeepAliveIntervalSeconds = 60
	nic.Start()
	nic.WaitForConnection()

	return nic
}
