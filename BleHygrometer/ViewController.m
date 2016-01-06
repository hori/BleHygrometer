//
//  ViewController.m
//  BleHygrometer
//

#import "ViewController.h"

#define kPeripheralName @"Arduino"
#define kPeripheralHumidityServiceUuid @"FFF0"
#define kPeripheralHumidityCharacteristicUuid @"FFF1"

@interface ViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, retain) CAGradientLayer *gradientLayer;

- (void)showHumidity:(float)humidity;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // init CBCentralManager
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];

    // init gradientLayer
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.gradientView.bounds;
    [self.gradientView.layer addSublayer:self.gradientLayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.gradientLayer.frame = self.gradientView.bounds;
}

- (void)showHumidity:(float)humidity
{
    // show humidity value
    [self.humidityLabel setText:[NSString stringWithFormat:@"%.1f%%", humidity]];

    // change gradient color
    float baseHue = (humidity*2.5-30)/255;
    self.gradientLayer.colors = @[
                                  (id)[UIColor colorWithHue:baseHue saturation:0.5 brightness:1.0 alpha:1.0].CGColor,
                                  (id)[UIColor colorWithHue:baseHue-0.05 saturation:1.0 brightness:0.7 alpha:1.0].CGColor];
}

#pragma mark CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self.centralManager scanForPeripheralsWithServices:nil
                                                        options:nil];
            break;
        default:
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    if ([peripheral.name isEqual:kPeripheralName])
    {
        self.peripheral = peripheral;
        [self.centralManager connectPeripheral:peripheral
                                       options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    NSArray *services = @[[CBUUID UUIDWithString:kPeripheralHumidityServiceUuid]];
    [peripheral discoverServices:services];
}


#pragma mark CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    NSArray *characteristics = @[[CBUUID UUIDWithString:kPeripheralHumidityCharacteristicUuid]];
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:characteristics
                                 forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties == CBCharacteristicPropertyNotify) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic
             error:(nullable NSError *)error
{
    float humidity;
    [characteristic.value getBytes:&humidity length:sizeof(humidity)];
    [self showHumidity:humidity];
}


@end
