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
	"os"

	"github.com/saichler/l8bus/go/overlay/health"
	"github.com/saichler/l8bus/go/overlay/vnet"
	"github.com/saichler/l8bus/go/overlay/vnic"
	"github.com/saichler/l8common/go/common"
	"github.com/saichler/l8types/go/ifs"
	"github.com/saichler/l8types/go/sec"
	"github.com/saichler/l8utils/go/utils/ipsegment"
	"github.com/saichler/l8web/go/web/server"
)

const vnetPort = 60605

func main() {
	hostname := os.Getenv("HOSTNAME")
	resources := common.CreateResources("vnet-"+hostname, false)
	resources.SysConfig().VnetPort = vnetPort
	net := vnet.NewVNet(resources)
	net.Start()
	resources.Logger().Info("vnet started!")

	startWebServer(4443, "web-"+hostname)
}

func startWebServer(port int, alias string) {
	resources := common.CreateResources(alias, false)
	resources.SysConfig().VnetPort = vnetPort

	nic := vnic.NewVirtualNetworkInterface(resources, nil)
	nic.Resources().SysConfig().KeepAliveIntervalSeconds = 60
	nic.Start()
	nic.WaitForConnection()

	domain, private, _ := nic.Resources().Certificate()
	if domain == "" || private == "" {
		d, p, _ := sec.CreateCertBundle()
		domainBytes, _ := base64.StdEncoding.DecodeString(d)
		privateBytes, _ := base64.StdEncoding.DecodeString(p)
		domain = string(domainBytes)
		private = string(privateBytes)
	}

	serverConfig := &server.RestServerConfig{
		Host:           ipsegment.MachineIP,
		Port:           port,
		Authentication: false,
		CertDomain:     domain,
		CertPrivate:    private,
		Prefix:         "/layer8/",
	}
	svr, err := server.NewRestServer(serverConfig)
	if err != nil {
		panic(err)
	}

	hs, ok := nic.Resources().Services().ServiceHandler(health.ServiceName, 0)
	if ok {
		svr.RegisterWebService(hs.WebService(), nic)
	}

	//Activate the webpoints service
	sla := ifs.NewServiceLevelAgreement(&server.WebService{}, ifs.WebService, 0, false, nil)
	sla.SetArgs(svr)
	nic.Resources().Services().Activate(sla, nic)

	nic.Resources().Logger().Info("Web Server Started!")
	svr.Start()
}
