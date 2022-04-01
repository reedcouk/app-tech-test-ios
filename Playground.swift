import UIKit
import CoreLocation
import JobDetailsScreen
import DataService

final class JobDetailsViewController: ModalPresentableViewController {
    private var attributedDescription: NSAttributedString? // Fully formatted job description text

    private var toastPosition: CGFloat {
        return self.view.safeAreaInsets.bottom + 10.0
    }
    private var appliedToastPosition: CGFloat {
        return self.view.safeAreaInsets.bottom + 101.0
    }
    
    private var dynamicToastPosition: CGFloat {
        let position = 0.0
        if (self.presenter.job.state.type == .withdrawn || self.presenter.job.state.type == .applied) {
            self.appliedToastPosition
        } else {
            self.toastPosition
        }
        return position
    }
    
    var presenter: Presenter!
    
    @IBOutlet
    private var scrollView: UIScrollView!
    @IBOutlet
    private var navigationBarBackgroundView: JobDetailsNavigationBar!
    @IBOutlet
    private var titleView: JobDetailsTitleView!
    @IBOutlet
    private var summaryView: JobDetailsSummaryView!
    @IBOutlet
    private var descriptionLabel: FoldingLabel!
    @IBOutlet
    private var descriptionLabelHeight: NSLayoutConstraint!
    @IBOutlet
    private var showMoreButton: ReedLink!
    @IBOutlet
    private var skillsView: JobDetailsSkilsView!
    @IBOutlet
    private var mapView: JobDetailsLocationView!
    @IBOutlet
    private var similarJobs: JobDetailsSimilarSearchesView!
    
    @IBOutlet
    var bannerGradientView: LinearGradientView!
    @IBOutlet
    var bannerImageView: UIImageView!
    @IBOutlet
    var brandedMediaCarousel: JobDetailsBrandedMediaCarousel!
    @IBOutlet
    var backgroudGradientView: LinearGradientView!
    @IBOutlet
    private var referenceView: JobDetailsCardBottomView!
    @IBOutlet
    private var referenceLabel: ReedLabel!
    @IBOutlet
    private var hideButtonView: JobDetailsActionButtonView!
    @IBOutlet
    var shareButtonView: JobDetailsActionButtonView!
    @IBOutlet
    var saveButtonView: JobDetailsActionButtonView!
    @IBOutlet
    var statusLabelsView: StatusLabelsView!
    
    // Applied middle section
    @IBOutlet
    private var appliedOnStampView: UIView!
    @IBOutlet
    private var appliedOnStampLabel: ReedLabel!
    
    // Applied bottom section
    @IBOutlet
    private var appliedButtonsView: UIStackView!
    @IBOutlet
    private var contactRecruiter: ReedLink!
    @IBOutlet
    private var appliedSeperator: UIView!
    @IBOutlet
    private var withdrawButton: UIButton!
    @IBOutlet
    private var applyButton: ReedButton!
    @IBOutlet
    private var saveButton: ReedButton!
    @IBOutlet
    private var applyButtonHeight: NSLayoutConstraint!
    @IBOutlet
    private var externalLinkView: UIView!
    @IBOutlet
    private var externalLinkButton: ReedLink!
    @IBOutlet
    private var applyButtonBottomView: UIView!
    @IBOutlet
    private var applyAndSaveButtonStackView: UIStackView!
    
    private lazy var dateFormatter = DateFormatter(dateFormat: "d MMM yyyy")
        
    private var isFirstLayout = true
    
    private lazy var fullWidthBackGestureRecognizer = UIPanGestureRecognizer()
    
    override func viewDidLoad() {
        self.saveButtonView.addTarget(self, action: #selector(didTapSave(_:)), for: .touchUpInside)
        self.hideButtonView.addTarget(self, action: #selector(didTapHide(_:)), for: .touchUpInside)
        self.shareButtonView.addTarget(self, action: #selector(didTapShare(_:)), for: .touchUpInside)
        self.navigationBarBackgroundView.addTarget(
            self, action: #selector(didTapBackButton(_:)), for: .touchUpInside
        )
        self.similarJobs.onScroll = { [weak self] in
            self?.presenter.didScrollSimilarCarousel()
        }
        self.brandedMediaCarousel.onScroll = { [weak self] in
            self?.presenter.didScrollMediaCarousel()
        }
        self.brandedMediaCarousel.onTap = { [weak self] index in
            self?.presenter.didTapMediaItem(at: index)
        }
        
        navigationController?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        setupFullWidthBackGesture()
        
        self.presenter.didLoad()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.presenter.willAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideToastIfNeeded()
        self.presenter.willDisappear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            self.presenter.didDisappear()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        /* The reason to do this calculation here is that this is the first place
         * where we have the `safeAreaInsets` that includes the navigation bar height. */
        guard self.isFirstLayout else {
            return
        }
        self.isFirstLayout = false
        // If its branded but no image then also shrink top
        let isBranded = self.presenter.job.brandedTemplate != nil
        self.navigationBarBackgroundView.configure(branded: isBranded)
        let bannerHeight = self.bannerImageView.frame.height
        let offset = self.navigationBarBackgroundView.frame.height
        
        self.scrollView.contentInset = UIEdgeInsets(
            top: isBranded ? bannerHeight - view.safeAreaInsets.top : offset,
            left: 0.0,
            bottom: 30,
            right: 0.0
        )
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        saveButton.setBackgroundColor(Color.button.primary.normal, for: .normal)
        saveButton.setBackgroundColor(Color.button.primary.disabled, for: .disabled)
    }
    
    // MARK: - Actions
    @IBAction
    func didTapOnMap(_ gesture: UITapGestureRecognizer) {
        presenter.didTapOnMap()
    }
    
    @IBAction
    func didTapBackButton(_ sender: UIButton) {
        presenter.didTapBackButton()
    }
    
    @IBAction
    func didTapExternalLink(_ sender: UIButton) {
        presenter.didTapExternalLink()
    }
    
    @IBAction
    func showMoreButtonTapped(_ sender: UIButton) {
        presenter.didTapShowMore(isFolded: self.descriptionLabel.folded)
    }
    
    @IBAction
    func didTapApply(_ sender: UIButton) {
        presenter.didTapApply()
    }
    
    @IBAction func didTapSaveButton(_ sender: UIButton) {
        presenter.didTapSave()
    }
    
    @IBAction
    func didTapWithdraw(_ sender: UIButton) {
        hideToastIfNeeded()
        presenter.didTapWithdraw()
    }
    
    @IBAction
    func didTapContact(_ sender: UIButton) {
        presenter.didTapContact()
    }
    
    // MARK: - Ui Setup
    
    private func setupFullWidthBackGesture() {
        if navigationController?.interactivePopGestureRecognizer != nil {
            fullWidthBackGestureRecognizer.setValue(interactivePopGestureRecognizer.value(forKey: "targets"), forKey: "targets")
            fullWidthBackGestureRecognizer.delegate = self
            view.addGestureRecognizer(fullWidthBackGestureRecognizer)
        }
    }
    
    private func setupUI(for job: Job) {
        if let brand = job.brandedTemplate {
            self.setup(with: brand)
        }
        
        titleView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        titleView.layer.cornerRadius = 12
        
        referenceView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        referenceView.layer.cornerRadius = 12
        
        navigationController?.navigationBar.tintColor = Colors.white
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        navigationBarBackgroundView.updateContent(alpha: 0)
    }
    
    @objc
    private func didTapSave(_ button: JobDetailsActionButtonView) {
        presenter.didTapSaveButton()
    }
    
    @objc
    private func didTapHide(_ button: JobDetailsActionButtonView) {
        presenter.didTapHideButton()
    }
    
    @objc
    private func didTapShare(_ button: JobDetailsActionButtonView) {
        presenter.didTapShare(sender: button)
    }
}

// MARK: - View implementation
extension JobDetailsViewController: JobDetailsScreen.View {
    func display(job: Job, statuses: [Status]?, userLocation: String?) {
        titleView.configure(title: job.title, company: job.companyName)
        loadCompanyLogo(url: job.logoLink)
        navigationBarBackgroundView.configure(title: job.title)
        summaryView.configure(location: job.location?.displayLocation ?? "-",
                              salary: job.displaySalary,
                              type: job.durationTitleLong,
                              posted: job.postedTitle)
        
        self.descriptionLabel.htmlText = job.description
        self.attributedDescription = self.descriptionLabel.attributedText
        self.statusLabelsView.configure(
            statuses: statuses,
            bottomOffset: 4,
            offset: 10
        )
        
        // If the label text is less than the minimum fold size then dont show the button
        let labelHeight = descriptionLabel.height(
            withConstrainedWidth: descriptionLabel?.frame.width ?? 0
        )
        if UIDevice.current.userInterfaceIdiom == .pad || labelHeight < 360 {
            descriptionLabelHeight.isActive = false
            showMoreButton.removeFromSuperview()
        } else {
            foldDescriptionLabel(fold: true)
        }
        
        referenceLabel.text = String(format: "jobDetails.reference".localized, "\(job.jobId)")
        
        let skills = job.skills ?? []
        if skills.isEmpty {
            skillsView.removeFromSuperview()
            skillsView = nil
        } else {
            skillsView.configure(skills: skills)
        }
        if let location = job.location?.location, let userLocation = userLocation {
            mapView.configure(from: userLocation, to: location)
        } else {
            mapView?.removeFromSuperview()
            mapView = nil
        }
        
        self.setupUI(for: job)
        self.view.layoutSubviews()
    }
    
    func activateContactRecruiterButton(isEnabled: Bool) {
        contactRecruiter.isEnabled = isEnabled
    }
    
    func shouldHideSaveButton(type: VacancyState) {
        let saveText = type == .shortlist ? "jobDetails.saved".localized : "jobDetails.save".localized
        saveButton.setTitle(saveText, for: .normal)
        
        let saveImageName = type == .shortlist ? Images.jobDetails.saved : Images.jobDetails.save
        saveButton.setImage(saveImageName, for: .normal)
    }
    
    func displayApplyAndSaveButtons(for type: ApplyType) {
        updateApplyAndSaveButtonsState(type: type)
    }
    
    func setOfflineState() {
        updateApplyAndSaveButtonsState(type: .offline)
    }
    
    func display(similarJobs: [Job]) {
        self.similarJobs.action = { [weak self] index in
            self?.presenter.didTapSimilarJob(at: index)
        }
        self.similarJobs.setup(jobs: similarJobs)
        self.similarJobs.isHidden = similarJobs.isEmpty
    }
    
    func removeSimilar(at index: Int, shouldHide: Bool) {
        self.similarJobs.remove(at: index, completion: {
            guard shouldHide else {
                return
            }
            UIView.animate(withDuration: 0.5, animations: {
                self.similarJobs.isHidden = true
            })
        })
    }
    
    func display(errorDescription: String) {
        showErrorAlert(errorDescription: errorDescription)
    }
    
    func display(vacancyState: VacancyState) {
        if vacancyState == .applied || vacancyState == .withdrawn {
            hideButtonView.isHidden = true
            saveButtonView.isHidden = true
            withdrawButton.isHidden = vacancyState == .withdrawn
            appliedOnStampView.isHidden = vacancyState != .withdrawn
            appliedButtonsView.isHidden = false
            appliedSeperator.isHidden = false
            applyButtonHeight.constant = 40
            NSLayoutConstraint.activate(
                [shareButtonView.heightAnchor.constraint(equalToConstant: 105)]
            )
            view.layoutIfNeeded()
        } else {
            hideButtonView.isActive = vacancyState == . discarded
            saveButtonView.isActive = vacancyState == . shortlist
        }
    }
    
    func display(externalUrl: URL) {
        self.externalLinkView.isHidden = false
        self.externalLinkButton.setTitle(externalUrl.absoluteString, for: .normal)
    }
    
    public func showErrorToast() {
        self.showToast(
            message: "error.default".localized,
            additionalMessage: "please_try_again".localized,
            icon: Toast.Image(image: Images.cross, tint: Color.toast.error),
            duration: .long,
            bottomInset: self.dynamicToastPosition,
            action: nil
        )
    }
    
    public func showOffline() {
        self.showToast(
            message: "search.offline_toast".localized,
            additionalMessage: "search.offline_toast_additional".localized,
            icon: Toast.Image(image: Images.wifi_off, tint: Colors.white),
            duration: .long,
            bottomInset: self.dynamicToastPosition
        )
    }
    
    public func showAppliedToast() {
        self.showReedStatus(for: .successJobApplication)
    }
    
    public func showWithdrawConfirmationToast() {
        self.showToast(
            message: "jobDetails.withrawn.toast.title".localized,
            additionalMessage: "jobDetails.withrawn.toast.message".localized,
            actionMessage: nil,
            icon: Toast.Image(image: Images.check, tint: Color.toast.success),
            duration: .long,
            bottomInset: self.appliedToastPosition,
            action: nil
        )
    }
    
    func showApplicationDismiss(cancelAction: @escaping () -> Void) {
        self.showReedAlert(
            title: "jobDetails.cancel_application_title".localized,
            message: "jobDetails.cancel_application_message".localized,
            actions: [
                AlertViewController.Action(title: "jobDetails.cancel_application_no".localized,
                                           style: .filled,
                                           action: { [weak self] in
                                            self?.presentedViewController?.dismiss(animated: true, completion: nil)
                                            self?.presenter.didTapKeepApplication()
                }),
                AlertViewController.Action(title: "jobDetails.cancel_application_yes".localized,
                                           style: .small,
                                           action: { [weak self] in
                                            self?.dismiss(
                                                animated: false,
                                                completion: {
                                                    cancelAction()
                                            })
                                            
                })
            ],
            layout: .vertical,
            completion: { [weak self] in
                self?.presenter.didShowCancelApplicationAlert()
        })
    }
    
    func showWithdrawAlert() {
        self.showReedAlert(
            title: "withdraw.title".localized,
            message: "withdraw.message".localized,
            actions: [
                AlertViewController.Action(title: "cancel".localized,  style: .bordered, action: { [weak self] in self?.presenter.didTapCancelWithdraw()}),
                AlertViewController.Action(title: "withdraw.withdraw".localized, style: .filled, action: { [weak self] in self?.presenter.didTapWithdrawConfirmed()})
            ],
            layout: .horizontal,
            completion: { [weak self] in
                self?.presenter.didShowWithdrawApplicationAlert()
        })
    }
    
    public func closeWithdrawAlert(completion: (() -> Void)?) {
        self.dismiss(animated: true, completion: completion)
    }
    
    public func showLoadingView() {
        self.showReedStatus(for: .loading)
    }
    
    public func dismissLoadingView(completion: @escaping () -> Void) {
        self.dismissReedStatus(completion: completion)
    }
    
    private func setup(with brand: BrandedTemplate) {
        // Banner and background
        let color = UIColor(hex: brand.bannerColourHex ?? Colors.mist.hex)
        self.bannerImageView.image = Images.brandedPlaceholder

        self.setBrandedColours(color: color)
        if let path = brand.bannerUrl {
            self.bannerImageView.loadImage(fromPath: path,
                                           placeholder: Images.brandedPlaceholder,
                                           completion: { (success, _) in
                if success {
                    let newColor = self.bannerImageView.image?.averageColor ?? color
                    self.setBrandedColours(color: newColor, hideImageGradient: false)
                }
            })
        }
        
        // Media gallery
        if !brand.mediaGallery?.isEmpty {
            self.brandedMediaCarousel.isHidden = false
                   self.brandedMediaCarousel.content = gallery
                   self.brandedMediaCarousel.title = String(format: "Company Info", self.presenter.job.companyName)
        } else {
            self.brandedMediaCarousel.isHidden = true
        }
    }
    
    public func showFullSizeMap(for job: Job) {
        guard let location = job.location?.location else {
            return
        }
        let alert = UIAlertController(
            title: "Maps",
            message: "View your map",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "open", style: .default, handler: { _ in self.mapView.showFullSizeMap(for: location, title: job.companyName)}))
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil)) (self.presentedViewController ?? self).present(alert, animated: true, completion: nil)
    }
    
    func displaySuccess(toast message: String) {
        self.showToast(
            message: message,
            icon: Toast.Image(image: "Toast.png", tint: Color.blue),
            duration: .swipe,
            bottomInset: self.appliedToastPosition
        )
    }
    
    private func loadCompanyLogo(url: URL?) {
        if let path = url {
            titleView.logoView.loadImage(fromUrl: path, placeholder: "Logo.png")
        }
    }
    
    func foldDescriptionLabel(fold: Bool) {
        descriptionLabelHeight.constant = fold ? 360 : descriptionLabel.height(
            withConstrainedWidth: descriptionLabel.frame.width
        )
                
        showMoreButton.setTitle(fold ?
            "jobDetails.read_more".localized :
            "jobDetails.show_less".localized,
                                for: .normal)
        showMoreButton.setImage(fold ? Images.chevronDown : Images.chevronUp, for: .normal)
        
        descriptionLabel.folded = fold
    }
    
    private func updateApplyAndSaveButtonsState(type: ApplyType) {
        switch type {
        case .external:
            let applyText = presenter.shouldShowSaveButton ? "jobDetails.apply".localized
                                                        : "jobDetails.apply_external".localized
            let applyButtonImage = presenter.shouldShowSaveButton ? Images.jobDetails.applyExternal : nil
            configureApplyAndSaveButtons(with: applyText,
                                         isApplyButtonEnabled: true,
                                         isSaveButtonHidden: !presenter.shouldShowSaveButton,
                                         applyButtonImage: applyButtonImage,
                                         backgroundState: .normal)
        case .ended:
            configureApplyAndSaveButtons(with: "jobDetails.apply_ended".localized,
                                         isApplyButtonEnabled: false,
                                         isSaveButtonHidden: true,
                                         applyButtonImage: nil,
                                         backgroundState: .disabled)
        case .applied(let date):
            let applyText = String(format: "Applied", dateFormatter.string(from: date))
            configureApplyAndSaveButtons(with: applyText,
                                         isApplyButtonEnabled: false,
                                         isSaveButtonHidden: true,
                                         applyButtonImage: nil,
                                         backgroundState: .disabled)
        case .withdrawn(let date):
            appliedOnStampLabel.text = String(
                format: "jobDetails.apply_applied_stamp".localized,
                dateFormatter.string(from: date)
            )
            configureApplyAndSaveButtons(with: "jobDetails.apply_withdrawn".localized,
                                         isApplyButtonEnabled: false,
                                         isSaveButtonHidden: true,
                                         applyButtonImage: nil,
                                         backgroundState: .disabled)
        case .notEligible:
            configureApplyAndSaveButtonsForNotEligibleState()
        case .offline:
            configureApplyAndSaveButtons(with: "offline".localized,
                                         isApplyButtonEnabled: false,
                                         isSaveButtonHidden: true,
                                         applyButtonImage: nil,
                                         backgroundState: .disabled)
        default:
            let applyText = presenter.shouldShowSaveButton ? "jobDetails.apply".localized
                                                        : "jobDetails.apply_now".localized
            configureApplyAndSaveButtons(with: applyText,
                                         isApplyButtonEnabled: true,
                                         isSaveButtonHidden: !presenter.shouldShowSaveButton,
                                         applyButtonImage: nil,
                                         backgroundState: .normal)
        }
    }
    
    private func configureApplyAndSaveButtons(with applyText: String,
                                              isApplyButtonEnabled: Bool,
                                              isSaveButtonHidden: Bool,
                                              applyButtonImage: UIImage?,
                                              backgroundState: UIControl.State) {
        let disabledBackground = UIColor(red: 10, green: 20, blue: 155, alpha: 1)
        let enabledBackground = UIColor(red: 50, green: 70, blue: 255, alpha: 1)
        let saveButtonNotHiddenBackgroundColor = Color.button.secondary.normal
        
        let backgroundColor = isApplyButtonEnabled ? enabledBackground : disabledBackground
        let applyAndSaveBackgroundColor = isSaveButtonHidden ? backgroundColor : saveButtonNotHiddenBackgroundColor
        
        applyButton.setTitle(applyText, for: .normal)
        applyButton.isEnabled = isApplyButtonEnabled
        applyButton.setImage(applyButtonImage, for: .normal)
        applyButton.setBackgroundColor(backgroundColor, for: backgroundState)
        
        saveButton.isHidden = isSaveButtonHidden
        saveButton.setBackgroundColor(saveButtonNotHiddenBackgroundColor, for: .normal)
        
        applyButtonBottomView.backgroundColor = applyAndSaveBackgroundColor
        applyAndSaveButtonStackView.backgroundColor = applyAndSaveBackgroundColor
    }
    
    private func configureApplyAndSaveButtonsForNotEligibleState() {
        applyButton.setTitle("jobDetails.apply_ineligible".localized, for: .normal)
        applyButton.isEnabled = false
        applyButton.setImage(nil, for: .normal)
        applyButton.setBackgroundColor(Color.button.secondary.disabled, for: .disabled)
        
        saveButton.isHidden = true
        saveButton.setBackgroundColor(UIColor(red: 33, green: 67, blue: 93, alpha: 1), for: .normal)
        
        applyButtonBottomView.backgroundColor = Color.button.primary.disabled
        applyAndSaveButtonStackView.backgroundColor = Color.button.primary.disabled
    }

    private func setBrandedColours(color: UIColor, hideImageGradient: Bool = true) {
        self.bannerImageView.backgroundColor = color
        self.backgroudGradientView.setup(for: .vertical,
                                         colors: [UIColor(red: 55, green: 48, blue: 150, alpha: 1), color])
        
        if !hideImageGradient {
            self.bannerGradientView.setup(for: .vertical,
                                          colors: [color, .clear],
                                          locations: [0.0, 0.4])
        }
    }
}

// MARK: - Scroll View Delegate
extension JobDetailsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != self.scrollView {
            return
        }
        var percent = (scrollView.contentOffset.y
            + self.navigationBarBackgroundView.frame.height
            - titleView.frame.minY)
            / titleView.frame.maxY
        percent = percent > 1 ? 1 : percent
        let color = Colors.white.withAlphaComponent(percent)
        navigationController?.navigationBar.tintColor = Colors.white.withAlphaComponent(percent)
        navigationController?.navigationBar.shadowImage = percent >= 0.99 ? nil : UIImage()
        navigationController?.navigationBar.setBackgroundImage(percent >= 0.99 ? nil : UIImage(), for: .default)
        navigationBarBackgroundView.updateContent(
            alpha: percent > 0.7 ? (percent - 0.7) * (1 / 0.3) : 0
        )
        navigationBarBackgroundView.backgroundColor = color
    }
}

extension JobDetailsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationViewController = navigationController else { return false }
        let isSystemSwipeToBackEnabled = navigationViewController.interactivePopGestureRecognizer?.isEnabled == true
        let isThereStackedViewControllers = navigationViewController.viewControllers.count > 1
        
        return isSystemSwipeToBackEnabled && isThereStackedViewControllers
    }
}

extension JobDetailsViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        if let coordinator = navigationController.topViewController?.transitionCoordinator {
            coordinator.notifyWhenInteractionChanges {[weak self] context in
                if !context.isCancelled {
                    self?.presenter.didSwipeBack()
                }
            }
        }
    }
}
